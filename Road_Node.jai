Road_Node :: struct {
    id: int;
    position: Vector3;
    connections: [..] Road_Connection;
    connected_blocks: [..] *Block;
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
    road.width = 1;
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
        array_add(*path, to);
        array_add(*queue, path);
    }
    while queue.count > 0 && found_path.count == 0 {
        v_path := array_copy(queue[0]);
        array_free(queue[0]);
        array_unordered_remove_by_index(*queue, 0);
        v := peek(v_path);
        for v.connections {
            w := it.to;
            if w == from && v_path.count > 2 && w != v_path[v_path.count-2] && (found_path.count == 0 || v_path.count < found_path.count) {
                array_copy(*found_path, v_path);
                continue;
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
        for block: blocks {
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
        }

        if !found_block {
            new_block_contains_another_block := false;
            for block: blocks {
                inside := false;
                for 0..found_path.count-1 {
                    node := found_path[it];
                    next := found_path[(it+1) % found_path.count];
                    x := block.centroid.x; y := block.centroid.z;
                    xi := node.position.x; yi := node.position.z;
                    xj := next.position.x; yj := node.position.z;
                    intersect := ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
                    if intersect then {
                        ANY_INTERSECTION_FAILS :: true;
                        #if ANY_INTERSECTION_FAILS {
                            inside = true;
                            break;
                        }
                        else inside = !inside;
                        
                    }
                }
                if inside {
                    new_block_contains_another_block = true;
                    break;
                }
            }
            if new_block_contains_another_block {
                log("whoops, nevermind, that block contains another block");
            }
            else {
                log("adding block");
                block: Block;
                block.height = TEMP_BLOCK_HEIGHT;
                block.type = cast(Block_Type) (blocks.count % get_enum_count(Block_Type)); //TEMP
                for 0..found_path.count-1 {
                    node := found_path[it];
                    /*next_node := found_path[(it+1) % found_path.count];
                    for node.connections {
                        if it.to.id == next_node.id {
                            array_add(*block.roads, it.road);
                            break;
                        }
                        array_add(*block.road_vertices, node.position);
                    }*/
                    array_add(*block.road_nodes, node);
                }
                do_block_calculations(*block);
                added_block := spawn(block);
                for found_path array_add(*it.connected_blocks, added_block);
                report_blocks();
            }
        }
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
    for connected_blocks do_block_calculations(it);
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
