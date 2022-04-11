Road_Node :: struct {
    id: int;
    position: Vector3;
    connections: [..] Road_Connection;
    connected_blocks: [..] *Block;
    corner_subdivisions: float = 1; //TODO
}
road_nodes: Bucket_Array(Road_Node, 1000, true);
spawn :: (using node: Road_Node) -> *Road_Node {
    new_node := node;
    new_node.id = road_nodes.count;
    return bucket_array_find_pointer(*road_nodes, bucket_array_add(*road_nodes, new_node));
}
render :: (using node: *Road_Node) {
    if connections.count == 0 then DrawCircle3D(position, 0.5, .{1,0,0}, 90, DARKGRAY);
    //DrawPoint3D(position, RED);
    //draw_axis(position, DARKGREEN);
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
    road.start = from.position;
    road.end = to.position;
    road.width = 1;
    spawned_road := spawn(road);
    conn_from.road, conn_to.road = spawned_road;
    array_add(*from.connections, conn_from);
    array_add(*to.connections, conn_to);
    recalculate(to, true);
    recalculate(from, true);



    GENERATE_BLOCKS :: true;
    #if GENERATE_BLOCKS {
        // now let's see if we need to make a Block (MCB)
        Node_Path :: [..] *Road_Node;
        checked_ids: [..] int;
        queue: [..] Node_Path;
        found_block := false;
        found_path: Node_Path;
        {
            path: Node_Path;
            array_add(*path, from);
            array_add(*path, to);
            array_add(*queue, path);
        }
        //while queue.count > 0 && found_path.count == 0 {
        while queue.count > 0 && (found_path.count == 0 || queue.count < found_path.count) {
            v_path := array_copy(queue[0]);
            array_free(queue[0]);
            array_unordered_remove_by_index(*queue, 0);
            v := peek(v_path);
            for v.connections {
                w := it.to;
                if w == from && v_path.count > 2 && w != v_path[v_path.count-2] && (found_path.count == 0 || v_path.count < found_path.count) {
                    new_block_contains_another_block := false;
                    for block: blocks {
                        inside := false;
                        for 0..v_path.count-1 {
                            node := v_path[it];
                            next := v_path[(it+1) % v_path.count];
                            x := block.centroid.x; y := block.centroid.z;
                            xi := node.position.x; yi := node.position.z;
                            xj := next.position.x; yj := next.position.z;
                            intersect := ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
                            if intersect then inside = !inside;
                        }
                        if inside {
                            new_block_contains_another_block = true;
                            break;
                        }
                    }
                    if !new_block_contains_another_block {
                        array_copy(*found_path, v_path);
                        continue;
                    }
                    else {
                        log("new block contained another block, trying again...");
                        continue;
                    }
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
            for found_path log("%", it.id);
            //TODO: sort found_path clockwise?
            found_block := false;
            // if we need this, then we need to move it into the logic above
            /*for block: blocks {
                if block.road_nodes.count != found_path.count then continue;
                found_start := false;
                start: int;
                for 0..block.road_nodes.count-1 {
                    node := block.road_nodes[it];
                    if node == found_path[0] {
                        found_start = true;
                        start = it;
                        break;
                    }
                }
                block_matches := false;
                block_matches_reverse := false;
                if found_start {
                    block_matches = true;
                    block_matches_reverse = true;
                    for 0..block.road_nodes.count-1 {
                        node := block.road_nodes[(start+it) % block.road_nodes.count];
                        if found_path[it] != node {
                            block_matches = false;
                            break;
                        }
                    }
                    for 0..block.road_nodes.count-1 {
                        reverse_index := (start-it) % block.road_nodes.count;
                        if reverse_index < 0 then reverse_index += block.road_nodes.count;
                        node := block.road_nodes[reverse_index];
                        if found_path[it] != node {
                            block_matches_reverse = false;
                            break;
                        }
                    }
                }
                if block_matches || block_matches_reverse {
                    log("whoops, nevermind, existing similar block found");
                    found_block = true;
                    break;
                }
            }*/

            if !found_block {
                log("adding block");
                block: Block;
                block.height = TEMP_BLOCK_HEIGHT;
                block.type = cast(Block_Type) (blocks.count % get_enum_count(Block_Type)); //TEMP
                for 0..found_path.count-1 {
                    node := found_path[it];
                    array_add(*block.road_nodes, node);
                }
                recalculate(*block);
                added_block := spawn(block);
                for found_path array_add(*it.connected_blocks, added_block);
                report_blocks();
            }
        }
        array_free(found_path);
    }




    return true;
}
reposition_road_node :: (using node: *Road_Node, new_position: Vector3) -> bool {
    prev_position := position;
    position = new_position;
    for connections {
        if it.road.start == prev_position {
            it.road.start = position;
        }
        else {
            it.road.end = position;
        }
    }
    recalculate(node, true);
    return true;
}

recalculate :: (using node: *Road_Node, recalculate_connected: bool = false) {
    // bubble_sort (can't use bubble_sort directly Because No Closures)
    {
        count := connections.count;
        last_j := count-2;
        first_j := 0;
        while true {
            latest_swap := -1;
            first_swap  := -1;
            for j : first_j..last_j {
                a := connections[j];
                b := connections[j+1];
                if compare_vertices_rotationally(a.to.position, b.to.position, position) {
                    connections[j]   = b;
                    connections[j+1] = a;
                    latest_swap = j;
                    if first_swap == -1  first_swap = j;
                }
            }
            if latest_swap == -1 break;
            last_j = latest_swap - 1;
            first_j = max(first_swap-1, 0);
        }
    }
    if connections.count == 1 {
        road := connections[0].road;
        flipped := road.start != position;
        if !flipped {
            array_reset(*road.left_start_vertices);
            array_reset(*road.right_start_vertices);
            left := get_left_side(road);
            right := get_right_side(road);
            array_add(*road.left_start_vertices, road.start);
            array_add(*road.right_start_vertices, road.start);
            array_add(*road.left_start_vertices, left.start);
            array_add(*road.right_start_vertices, right.start);
            
        }
        else {
            array_reset(*road.left_end_vertices);
            array_reset(*road.right_end_vertices);
            left := get_left_side(road);
            right := get_right_side(road);
            array_add(*road.left_end_vertices, left.end);
            array_add(*road.right_end_vertices, right.end);
            array_add(*road.left_end_vertices, road.end);
            array_add(*road.right_end_vertices, road.end);
        }
    }
    else for 0..connections.count-1 {
        road := connections[it].road;
        left_vertices: *[..] Vector3;
        right_vertices: *[..] Vector3;
        conn_left := connections[ifx it == 0 then connections.count-1 else it-1];
        conn_right := connections[ifx it == connections.count-1 then 0 else it+1];
        flipped := road.start != position;
        if !flipped {
            left_vertices = *road.left_start_vertices;
            right_vertices = *road.right_start_vertices;
        }
        else {
            left_vertices = *road.left_end_vertices;
            right_vertices = *road.right_end_vertices;
        }
        array_reset(left_vertices);
        array_reset(right_vertices);
        {
            conn := ifx flipped then conn_right else conn_left;
            conn_flipped := conn.road.start != position;
            which := !conn_flipped ^ flipped;
            a := get_left_side_infinity(road);
            b := ifx which then get_right_side_infinity(conn.road) else get_left_side_infinity(conn.road);
            new_vertex: Vector2;
            if CheckCollisionLines(
                xy(a.start.x, a.start.z),
                xy(a.end.x, a.end.z),
                xy(b.start.x, b.start.z),
                xy(b.end.x, b.end.z),
                *new_vertex
            ) then array_add(left_vertices, xyz(new_vertex.x, 0, new_vertex.y));
        }
        {
            conn := ifx flipped then conn_left else conn_right;
            conn_flipped := conn.road.start != position;
            which := !conn_flipped ^ flipped;
            a := get_right_side_infinity(road);
            b := ifx which then get_left_side_infinity(conn.road) else get_right_side_infinity(conn.road);
            new_vertex: Vector2;
            if CheckCollisionLines(
                xy(a.start.x, a.start.z),
                xy(a.end.x, a.end.z),
                xy(b.start.x, b.start.z),
                xy(b.end.x, b.end.z),
                *new_vertex
            ) then array_add(right_vertices, xyz(new_vertex.x, 0, new_vertex.y));
        }
    }
    if recalculate_connected then for connections recalculate(it.to);
    for connected_blocks recalculate(it);
}
delete_road_node :: (using node: *Road_Node) -> bool {
    //TODO
    return true;
}

// reversed from https://stackoverflow.com/questions/6989100/sort-points-in-clockwise-order
compare_vertices_rotationally :: (a: Vector3, b: Vector3, center: Vector3) -> bool {
    if a.x-center.x >= 0 && b.x-center.x < 0 then return false;
    if a.x-center.x < 0 && b.x-center.x >= 0 then return true;
    if a.x-center.x == 0 && b.x-center.x == 0 {
        if a.z-center.z >= 0 || b.z-center.z >= 0 then return a.z<b.z;
        else return b.z<a.z;
    }
    det := (a.x-center.x)*(b.z-center.z) - (b.x-center.x)*(a.z-center.z);
    if det < 0 then return false;
    if det > 0 then return true;
    return (a.x-center.x)*(a.x-center.x)+(a.z-center.z)*(a.z-center.z) < (b.x-center.x)*(b.x-center.x)+(b.z-center.z)*(b.z-center.z);
}

Road_Connection :: struct {
    to: *Road_Node;
    road: *Road;
}
operator == :: (a: Road_Connection, b: Road_Connection) -> bool {
    return a.to == b.to && a.road == b.road;
}
