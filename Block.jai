Block :: struct {
    id:             int;
    type:           Block_Type;
    road_nodes:     [..] *Road_Node;
    vertices:       [..] Vector3;
    centroid:       Vector3;
    height: float;
    display_height: float;
}
blocks: Bucket_Array(Block, 1000, true);
Block_Type :: enum { RESIDENTIAL; COMMERCIAL; INDUSTRIAL; }

spawn :: (using block: Block) -> *Block {
    new_block := block;
    new_block.id = blocks.count;
    return bucket_array_find_pointer(*blocks, bucket_array_add(*blocks, new_block));
}

simulate :: (using block: *Block, dt: float) {
    display_height = lerp(display_height, height, 10*dt);
}

render :: (using block: *Block) {
    for 0..vertices.count-1 {
        start := vertices[it];
        end := vertices[(it+1) % vertices.count];
        offset_bottom := Vector3.{0, 0, 0};
        offset_top := xyz(0, display_height, 0);
        color := get_block_color(block);
        DrawLine3D(start+offset_bottom, end+offset_bottom, color);
        DrawLine3D(start+offset_top, end+offset_top, color);
        DrawLine3D(start+offset_bottom, start+offset_top, color);
    }
}

render_2d :: (using block: *Block) {
    color := get_block_color(block);
    {
        offset_centroid := centroid + xyz(0, display_height/2.0, 0);
        cstr := tcprint("%", id);
        pos := GetWorldToScreen(offset_centroid, game.camera) - MeasureTextEx(the_font, cstr, xx the_font.baseSize, 1)*0.5;
        DrawTextEx(the_font, cstr, pos, xx the_font.baseSize, 1, color);
    }
}

get_block_color :: (using block: *Block) -> Color {
    if #complete type == {
        case .RESIDENTIAL; return LIME;
        case .COMMERCIAL;  return BLUE;
        case .INDUSTRIAL;  return YELLOW;
    }
}

do_block_calculations :: (using block: *Block) {
    calculate_inner_polygon(block);
    centroid = calculate_centroid(vertices);
}

calculate_centroid :: (vertices: [] Vector3) -> Vector3 {
    signed_area := 0.0;
    centroid_2d: Vector2;
    partial_signed_area := 0.0;
    for 0..vertices.count-1 {
        v := vertices[it];
        n := vertices[(it+1) % vertices.count];
        current := xy(v.x, v.z);
        next := xy(n.x, n.z);
        partial_signed_area = current.x*next.y - next.x*current.y;
        signed_area += partial_signed_area;
        centroid_2d += (current+next) * partial_signed_area;
    }
    centroid_2d /= (3.0*signed_area);
    return xyz(centroid_2d.x, 0, centroid_2d.y);
}

Line_Segment :: struct { start: Vector3; end: Vector3; }
make_line_segment :: (start: Vector3, end: Vector3) -> Line_Segment {
    ls: Line_Segment = ---;
    ls.start = start;
    ls.end = end;
    return ls;
}
seg :: make_line_segment;

//TODO: make this work in all cases instead of just the naive ones
calculate_inner_polygon :: (using block: *Block) {
    array_reset(*vertices);
    road_vertices: [..] Vector3;
    for 0..road_nodes.count-1 {
        node := road_nodes[it];
        next_node := road_nodes[(it+1) % road_nodes.count];
        for node.connections {
            if it.to == next_node {
                array_add(*road_vertices, node.position);
                break;
            }
        }
    }
    road_centroid := calculate_centroid(road_vertices);
    segs: [..] Line_Segment; defer array_free(segs);
    connected_roads: [..] *Road; defer array_free(connected_roads);
    for 0..road_nodes.count-1 {
        node := road_nodes[it];
        next_node := road_nodes[(it+1) % road_nodes.count];
        for node.connections {
            if it.to == next_node {
                array_add(*connected_roads, it.road);
            }
        }
    }
    for connected_roads {
        using it;
        theta := atan2(end.z-start.z, end.x-start.x) + PI/2;
        offset := xyz(cos(theta)*(width/2), 0, sin(theta)*(width/2));
        midpoint1 := ((start+offset + end+offset) * 0.5);
        midpoint2 := ((start-offset + end-offset) * 0.5);
        if distance(midpoint1, road_centroid) < distance(midpoint2, road_centroid) {
            array_add(*segs, seg(start+offset, end+offset));
        }
        else {
            array_add(*segs, seg(start-offset, end-offset));
        }
    }
    //TODO: replace this with something less ridiculous that only checks connected segments & makes a joint if they don't overlap
    for first_it: 0..segs.count-1 {
        first_seg := segs[first_it];
        for second_it: 0..segs.count-1 {
            if first_it == second_it then continue;
            second_seg := segs[second_it];
            new_vertex: Vector2;
            if CheckCollisionLines(
                xy(first_seg.start.x, first_seg.start.z),
                xy(first_seg.end.x, first_seg.end.z),
                xy(second_seg.start.x, second_seg.start.z),
                xy(second_seg.end.x, second_seg.end.z),
                *new_vertex
            ) {
                found := false;
                for vertices {
                    vertex_2d := xy(it.x, it.z);
                    if vertex_2d == new_vertex {
                        found = true;
                        break;
                    }
                }
                if !found {
                    array_add(*vertices, xyz(new_vertex.x, 0, new_vertex.y)); //TODO: 0??
                }
            }
            else {
                //TODO: concave polygons, somehow
            }
        }
    }
    // bubble_sort (can't use bubble_sort directly Because No Closures)
    {
        count := vertices.count;
        last_j := count-2;
        first_j := 0;
        while true {
            latest_swap := -1;
            first_swap  := -1;
            for j : first_j..last_j {
                a := vertices[j];
                b := vertices[j+1];
                compare := ifx atan2(a.z - road_centroid.z, a.x - road_centroid.x) > atan2(b.z-road_centroid.z, b.x-road_centroid.x) then -1 else 1;
                if compare > 0 {
                    vertices[j]   = b;
                    vertices[j+1] = a;
                    latest_swap = j;
                    if first_swap == -1  first_swap = j;
                }
            }
            if latest_swap == -1 return;
            last_j = latest_swap - 1;
            first_j = max(first_swap-1, 0);
        }
    }
}

report_blocks :: () {
    log("BLOCK REPORT");
    for blocks {
        sb: String_Builder; defer free_buffers(*sb);
        for it.road_nodes print_to_builder(*sb, "% ", it.id);
        log("---\nBLOCK %: %", it.id, builder_to_string(*sb));
    }
}

TEMP_BLOCK_HEIGHT :: 1;
