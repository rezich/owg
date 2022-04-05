Road_Node :: struct {
    id: int;
    position: Vector3;
    connections: [..] Road_Connection;
}
road_nodes: Bucket_Array(Road_Node, 1000, true);
spawn :: (using node: Road_Node) -> *Road_Node {
    new_node := node;
    new_node.id = road_nodes.count;
    return bucket_array_find_pointer(*road_nodes, bucket_array_add(*road_nodes, new_node));
}
render :: (using node: *Road_Node) {
    DrawCircle3D(position, 0.5, .{1,0,0}, 90, DARKGREEN);
}
render_2d :: (using node: *Road_Node) {
    offset_position := position + .{0, 0.25, 0};
    cstr := tcprint("%", id);
    pos := GetWorldToScreen(offset_position, game.camera) - MeasureTextEx(the_font, cstr, xx the_font.baseSize, 1)*0.5;
    DrawTextEx(the_font, cstr, pos, xx the_font.baseSize, 1, GREEN);
}
connect_road_nodes :: (from: *Road_Node, to: *Road_Node) -> bool {
    if from == to then return false;
    conn_from: Road_Connection;
    conn_from.to = to;
    conn_to: Road_Connection;
    conn_to.to = from;
    for from.connections if it == conn_from then return false;
    for to.connections if it == conn_to then return false;
    road: Road;
    road.start = to.position;
    road.end = from.position;
    road.width = 2;
    spawned_road := spawn(road);
    conn_from.road, conn_to.road = spawned_road;
    array_add(*from.connections, conn_from);
    array_add(*to.connections, conn_to);




    // now let's see if we need to make a Block (MCB)
    Node_Path :: [..] *Road_Node;
    checked_ids: [..] int;
    queue: [..] Node_Path;
    found_block := false;
    found_path: Node_Path;
    {
        path: Node_Path;
        array_add(*path, from);
        array_add(*queue, path);
    }
    while queue.count > 0 && found_path.count == 0 {
        v_path := array_copy(queue[0]);
        array_free(queue[0]);
        array_unordered_remove_by_index(*queue, 0);
        v := peek(v_path);
        for v.connections {
            w := it.to;
            if w == from && v_path.count > 2 {
                array_copy(*found_path, v_path);
                break;
            }
            in_v_path, _ := array_find(v_path, w);
            if !in_v_path {
                path: Node_Path;
                for v_path array_add(*path, it);
                array_add(*path, w);
                array_add(*queue, path);
            }
        }
        array_free(v_path);
    }
    for queue array_free(it);
    array_free(queue);
    if found_path.count > 0 {
        log("FOUND BLOCK");
        block: Block;
        block.height = 4;
        for 0..found_path.count-1 {
            node := found_path[it];
            next_node := found_path[(it+1) % found_path.count];
            for node.connections {
                if it.to.id == next_node.id {
                    array_add(*block.roads, it.road);
                    break;
                }
                array_add(*block.road_vertices, node.position);
            }
        }
        do_block_calculations(*block);
        array_add(*blocks, block);
    }
    array_free(found_path);




    return true;
}
reposition_road_node :: (using node: *Road_Node, new_position: Vector3) -> bool {
    for connections {
        if it.road.start == position then it.road.start = new_position;
        else it.road.end = new_position;
    }
    position = new_position;
    return true;
}
delete_road_node :: (using node: *Road_Node) -> bool {
    //TODO
    return true;
}

Road_Connection :: struct {
    to: *Road_Node;
    road: *Road;
}
operator == :: (a: Road_Connection, b: Road_Connection) -> bool {
    return a.to == b.to && a.road == b.road;
}

Road :: struct {
    id: int;
    start: Vector3;
    end: Vector3;
    width: float;
    display_width: float;
    //mesh: Mesh;
    //model: Model;
}

roads: Bucket_Array(Road, 1000, true);

spawn :: (using road: Road) -> *Road {
    new_road := road;
    new_road.id = roads.count;
    return bucket_array_find_pointer(*roads, bucket_array_add(*roads, new_road));
}

/*spawn_at_end :: (using road: Road, previous: *Road) -> *Road {
    new_road := road;
    new_road.start = previous.end;
    return spawn(new_road);
}*/

simulate :: (using road: *Road, dt: float) {
    display_width = lerp(display_width, width, 10*dt);
}

render :: (using road: *Road) {
    DrawLine3D(start, end, RED);

    length := cast(int) floor(distance(xy(start.x, start.z), xy(end.x, end.z)));
    theta := atan2(end.z-start.z, end.x-start.x) + PI/2;
    offset := xyz(cos(theta)*(display_width/2), 0, sin(theta)*(display_width/2));
    /*for 0..length
    {
        p := lerp(start, end, cast(float) it / cast(float) length);
        DrawLine3D(p+offset, p-offset, MAGENTA);
    }*/
    DrawLine3D(start+offset, end+offset, PINK);
    DrawLine3D(start-offset, end-offset, PINK);
}

render_2d :: (using road: *Road) {
    midpoint := ((start + end) * 0.5) + .{0, 0.25, 0};
    cstr := tcprint("%", id);
    pos := GetWorldToScreen(midpoint, game.camera) - MeasureTextEx(the_font, cstr, xx the_font.baseSize, 1)*0.5;
    DrawTextEx(the_font, cstr, pos, xx the_font.baseSize, 1, RED);
}

Block :: struct {
    id:             int;
    type:           enum { RESIDENTIAL; COMMERCIAL; INDUSTRIAL; }
    roads:          [..] *Road;
    road_vertices:  [..] Vector3;
    vertices:       [..] Vector3;
    road_centroid:  Vector3;
    centroid:       Vector3;
    height: float;
    display_height: float;
}

blocks: [..] Block;

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
        offset_centroid := centroid + .{0, 2, 0};
        cstr := tcprint("%", id);
        pos := GetWorldToScreen(offset_centroid, game.camera) - MeasureTextEx(the_font, cstr, xx the_font.baseSize, 1)*0.5;
        DrawTextEx(the_font, cstr, pos, xx the_font.baseSize, 1, color);
    }
    /*{
        offset_centroid := road_centroid + .{0, 0.25, 0};
        cstr := tcprint("%", id);
        pos := GetWorldToScreen(offset_centroid, game.camera) - MeasureTextEx(the_font, cstr, xx the_font.baseSize, 1)*0.5;
        DrawTextEx(the_font, cstr, pos, xx the_font.baseSize, 1, DARKGREEN);
    }*/
    /*for roads {
        using it;
        theta := atan2(end.z-start.z, end.x-start.x) + PI/2;
        offset := xyz(cos(theta)*(width/2), 0, sin(theta)*(width/2));
        //road_vec := end-start;
        {
            midpoint := ((start+offset + end+offset) * 0.5) + .{0, 0.25, 0};
            road_vec := end+offset - start+offset;
            result := distance(midpoint, road_centroid); //dot(road_vec, road_centroid);
            cstr := tcprint("%", result);
            pos := GetWorldToScreen(midpoint, game.camera) - MeasureTextEx(the_font, cstr, xx the_font.baseSize, 1)*0.5;
            color := ifx result > 0 then LIME else DARKGREEN;
            DrawTextEx(the_font, cstr, pos, xx the_font.baseSize, 1, color);
        }
        {
            midpoint := ((start-offset + end-offset) * 0.5) + .{0, 0.25, 0};
            road_vec := end-offset - start-offset;
            result := distance(midpoint, road_centroid); //dot(road_vec, road_centroid);
            cstr := tcprint("%", result);
            pos := GetWorldToScreen(midpoint, game.camera) - MeasureTextEx(the_font, cstr, xx the_font.baseSize, 1)*0.5;
            color := ifx result > 0 then LIME else DARKGREEN;
            DrawTextEx(the_font, cstr, pos, xx the_font.baseSize, 1, color);
        }
    }*/
}

get_block_color :: (using block: *Block) -> Color {
    if #complete type == {
        case .RESIDENTIAL; return LIME;
        case .COMMERCIAL;  return BLUE;
        case .INDUSTRIAL;  return YELLOW;
    }
}

do_block_calculations :: (using block: *Block) {
    road_centroid = calculate_centroid(road_vertices);
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
    segs: [..] Line_Segment;
    for roads {
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

/*Building :: struct {
    position: Vector3;
    dimensions: Vector3;
}

buildings: Bucket_Array(Building, 1000);

spawn :: (using building: Building) {
    bucket_array_add(*buildings, building);
}

render :: (using building: *Building) {
    DrawCubeWiresV(position, dimensions, BLUE);
}*/

/*generate_world :: () {
}*/

/*******************************************************************************
TODO:
    - ignore MCB for blocks that exist(!!)
    - probably reorder vertices for blocks
*******************************************************************************/
