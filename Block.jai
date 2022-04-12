Block :: struct {
    id:                int;
    type:              Block_Type;
    road_nodes:        [..] *Road_Node;
    vertices:          [..] Vector3;
    triangles:         [..] Triangle;
    centroid:          Vector3;
    height:            float;
    display_height:    float;
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
    /*for 0..vertices.count-1 {
        start := vertices[it];
        end := vertices[(it+1) % vertices.count];
        offset_bottom := Vector3.{0, 0, 0};
        offset_top := xyz(0, display_height, 0);
        color := get_block_color(block);
        DrawLine3D(start+offset_bottom, end+offset_bottom, color);
        DrawLine3D(start+offset_top, end+offset_top, color);
        DrawLine3D(start+offset_bottom, start+offset_top, color);
    }*/
    for triangles DrawTriangle3D(vertices[it.a], vertices[it.b], vertices[it.c], RED);
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

recalculate :: (using block: *Block) {
    calculate_inner_polygon(block);
    centroid = calculate_centroid(vertices);
    block_triangluate(block);
    log("-- triangles --");
    for triangles log("% % %", vertices[it.a], vertices[it.b], vertices[it.c]);
    log("---------------");
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
                array_add_if_not_prev_or_first(*road_vertices, node.position);
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
                using it.road;
                //backwards := (it.to.position != it.road.end) ^ (node.position != it.road.start);
                /*backwards := node.position != it.road.start || it.to.position != it.road.end;
                if backwards {
                    for < left_end_vertices array_add(*vertices, it);
                    for < left_start_vertices array_add(*vertices, it);
                }
                else {
                    for right_start_vertices array_add(*vertices, it);
                    for right_end_vertices array_add(*vertices, it);
                }*/
                backwards := node.position != it.road.start;
                backwards2 := false; //it.to.position != it.road.end;
                if !backwards2 {
                    if backwards {
                        for < left_end_vertices array_add_if_not_prev_or_first(*vertices, it);
                        for < left_start_vertices array_add_if_not_prev_or_first(*vertices, it);
                    }
                    else {
                        for right_start_vertices array_add_if_not_prev_or_first(*vertices, it);
                        for right_end_vertices array_add_if_not_prev_or_first(*vertices, it);
                    }
                }
                else {
                    if backwards {
                        for < right_end_vertices array_add_if_not_prev_or_first(*vertices, it);
                        for < right_start_vertices array_add_if_not_prev_or_first(*vertices, it);
                    }
                    else {
                        for left_start_vertices array_add_if_not_prev_or_first(*vertices, it);
                        for left_end_vertices array_add_if_not_prev_or_first(*vertices, it);
                    }
                }
                break;
            }
        }
    }
}

array_add_if_not_prev_or_first :: inline (array: *[..] $T, item: T) {
    if array.count == 0 || ((<<array)[array.count-1] != item && (<<array)[0] != item) then array_add(array, item);
}

report_blocks :: () {
    log("BLOCK REPORT");
    for blocks {
        sb: String_Builder; defer free_buffers(*sb);
        for it.road_nodes print_to_builder(*sb, "% ", it.id);
        log("---\nBLOCK %: %", it.id, builder_to_string(*sb));
    }
}

Triangle :: struct {
    a, b, c: int;
}
tri :: (a: int, b: int, c: int) -> Triangle {
    t: Triangle;
    t.a = a;
    t.b = b;
    t.c = c;
    return t;
}

TEMP_BLOCK_HEIGHT :: 1;
