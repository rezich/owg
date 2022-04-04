Road :: struct {
    id: int;
    start: Vector3;
    end: Vector3;
    width: float;
    end_connections: [..] *Road;
    //mesh: Mesh;
    //model: Model;
}

roads: Bucket_Array(Road, 1000, true);

spawn :: (using road: Road) -> *Road {
    new_road := road;
    new_road.id = roads.count;
    loc := bucket_array_add(*roads, new_road);
    spawned := bucket_array_find_pointer(*roads, loc);
    for roads {
        if it == spawned then continue;
        if spawned.end == it.start then array_add(*spawned.end_connections, it);
        if spawned.start == it.end then array_add(*it.end_connections, spawned);
    }
    return spawned;
}

spawn_at_end :: (using road: Road, previous: *Road) -> *Road {
    new_road := road;
    new_road.start = previous.end;
    return spawn(new_road);
}

render :: (using road: *Road) {
    DrawLine3D(start, end, RED);

    length := cast(int) floor(distance(xy(start.x, start.z), xy(end.x, end.z)));
    theta := atan2(end.z-start.z, end.x-start.x) + PI/2;
    offset := xyz(cos(theta)*(width/2), 0, sin(theta)*(width/2));
    /*for 0..length
    {
        p := lerp(start, end, cast(float) it / cast(float) length);
        DrawLine3D(p+offset, p-offset, GREEN);
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
}

blocks: [..] Block;

render :: (using block: *Block) {
    for 0..vertices.count-1 {
        start := vertices[it];
        end := vertices[(it+1) % vertices.count];
        offset_bottom := Vector3.{0, 0, 0};
        offset_top := Vector3.{0, 4, 0};
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

generate_world :: () {
    first_road: *Road;
    last_road: *Road;
    comm_road1: *Road;
    comm_road2: *Road;
    {
        block: Block;
        block.id = 0;
        block.type = .RESIDENTIAL;
        {
            r: Road;
            r.start = .{0, 0, 0};
            r.end = .{0, 0, -10};
            r.width = 4;
            last_road = spawn(r);
            first_road = last_road;
            comm_road1 = last_road;
            array_add(*block.roads, last_road);
            array_add(*block.road_vertices, last_road.end);
        }
        {
            r: Road;
            r.end = .{-10, 0, -10};
            r.width = 2;
            last_road = spawn_at_end(r, last_road);
            array_add(*block.roads, last_road);
            array_add(*block.road_vertices, last_road.end);
        }
        {
            r: Road;
            r.end = .{-10, 0, 0};
            r.width = 2;
            last_road = spawn_at_end(r, last_road);
            array_add(*block.roads, last_road);
            array_add(*block.road_vertices, last_road.end);
        }
        {
            r: Road;
            r.end = .{0, 0, 0};
            r.width = 2;
            last_road = spawn_at_end(r, last_road);
            array_add(*block.roads, last_road);
            array_add(*block.road_vertices, last_road.end);
        }
        do_block_calculations(*block);
        array_add(*blocks, block);
    }
    {
        block: Block;
        block.id = 1;
        block.type = .INDUSTRIAL;
        {
            r: Road;
            r.end = .{10, 0, 0};
            r.width = 2;
            last_road = spawn_at_end(r, last_road);
            comm_road2 = last_road;
            array_add(*block.roads, last_road);
            array_add(*block.road_vertices, last_road.end);
        }
        {
            r: Road;
            r.end = .{10, 0, 10};
            r.width = 2;
            last_road = spawn_at_end(r, last_road);
            array_add(*block.roads, last_road);
            array_add(*block.road_vertices, last_road.end);
        }
        /*{
            r: Road;
            r.end = .{0, 0, 10};
            r.width = 2;
            last_road = spawn_at_end(r, last_road);
            array_add(*block.roads, last_road);
            array_add(*block.road_vertices, last_road.end);
        }*/
        {
            r: Road;
            r.end = .{0, 0, 0};
            r.width = 4;
            last_road = spawn_at_end(r, last_road);
            array_add(*block.roads, last_road);
            array_add(*block.road_vertices, last_road.end);
        }
        do_block_calculations(*block);
        array_add(*blocks, block);
    }
    /*{
        block: Block;
        block.id = 2;
        block.type = .COMMERCIAL;
        array_add(*block.roads, comm_road1);
        array_add(*block.road_vertices, comm_road1.end);
        array_add(*block.roads, comm_road2);
        array_add(*block.road_vertices, comm_road2.end);
        {
            r: Road;
            r.end = .{10, 0, 0};
            r.width = 2;
            last_road = spawn_at_end(r, first_road);
            array_add(*block.roads, last_road);
            array_add(*block.road_vertices, last_road.end);
        }
        do_block_calculations(*block);
        array_add(*blocks, block);
    }*/

    print("\nROADS\n-----\n");
    for roads {
        sb: String_Builder; init_string_builder(*sb); defer free_buffers(*sb);
        for it.end_connections print_to_builder(*sb, "    Road #%\n", it.id);
        print("Road #%\n  start: %\n  end:   %\n  width: %\n  end_connections:\n%\n", it.id, it.start, it.end, it.width, builder_to_string(*sb));
    }

    print("\nBLOCKS\n------\n");
    for blocks {
        sb1: String_Builder; init_string_builder(*sb1); defer free_buffers(*sb1);
        sb2: String_Builder; init_string_builder(*sb2); defer free_buffers(*sb2);
        sb3: String_Builder; init_string_builder(*sb3); defer free_buffers(*sb3);
        for it.roads print_to_builder(*sb1, "    Road #%\n", it.id);
        for it.road_vertices print_to_builder(*sb2, "    %\n", it);
        for it.vertices print_to_builder(*sb3, "    %\n", it);
        print("Block #%\n  road_centroid: %\n  roads:\n%  road_vertices:\n%  vertices:\n%", it.id, it.road_centroid, builder_to_string(*sb1), builder_to_string(*sb2), builder_to_string(*sb3));
    }

    /*{
        b: Building;
        b.position = .{7.5, 5, 8};
        b.dimensions = .{5, 5, 5};
        spawn(b);
    }*/
    
}
