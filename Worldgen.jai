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
    DrawLine3D(start+offset, end+offset, MAGENTA);
    DrawLine3D(start-offset, end-offset, MAGENTA);
}

render_2d :: (using road: *Road) {
    midpoint := ((start + end) * 0.5) + .{0, 0.25, 0};
    cstr := tcprint("%", id);
    pos := GetWorldToScreen(midpoint, game.camera) - MeasureTextEx(the_font, cstr, xx the_font.baseSize, 1);
    DrawTextEx(the_font, cstr, pos, xx the_font.baseSize, 1, RED);
}

Block :: struct {
    id:             int;
    roads:          [..] *Road;
    road_vertices:  [..] Vector3;
    vertices:       [..] Vector3;
    road_centroid:  Vector3;
}

render_2d :: (using block: *Block) {
    offset_centroid := road_centroid + .{0, 0.25, 0};
    cstr := tcprint("%", id);
    pos := GetWorldToScreen(offset_centroid, game.camera) - MeasureTextEx(the_font, cstr, xx the_font.baseSize, 1);
    DrawTextEx(the_font, cstr, pos, xx the_font.baseSize, 1, GREEN);
}

calculate_road_centroid :: (using block: *Block) {
    signed_area := 0.0;
    current: Vector2;
    next: Vector2;
    centroid_2d: Vector2;
    partial_signed_area := 0.0;
    for 0..road_vertices.count-1 {
        v := road_vertices[it];
        n := road_vertices[(it+1) % road_vertices.count];
        current = xy(v.x, v.z);
        next = xy(n.x, n.z);
        partial_signed_area = current.x*next.y - next.x*current.y;
        signed_area += partial_signed_area;
        centroid_2d += (current+next) * partial_signed_area;
    }
    centroid_2d /= (3.0*signed_area);
    road_centroid = xyz(centroid_2d.x, 0, centroid_2d.y);
}

blocks: [..] Block;

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
    {
        block: Block;
        block.id = 0;
        {
            r: Road;
            r.start = .{0, 0, 0};
            r.end = .{0, 0, -10};
            r.width = 4;
            last_road = spawn(r);
            first_road = last_road;
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
        calculate_road_centroid(*block);
        array_add(*blocks, block);
    }
    {
        block: Block;
        block.id = 1;
        {
            r: Road;
            r.end = .{10, 0, 0};
            r.width = 2;
            last_road = spawn_at_end(r, last_road);
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
        {
            r: Road;
            r.end = .{0, 0, 10};
            r.width = 2;
            last_road = spawn_at_end(r, last_road);
            array_add(*block.roads, last_road);
            array_add(*block.road_vertices, last_road.end);
        }
        {
            r: Road;
            r.end = .{0, 0, 0};
            r.width = 4;
            last_road = spawn_at_end(r, last_road);
            array_add(*block.roads, last_road);
            array_add(*block.road_vertices, last_road.end);
        }
        calculate_road_centroid(*block);
        array_add(*blocks, block);
    }

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
        for it.roads print_to_builder(*sb1, "    Road #%\n", it.id);
        for it.road_vertices print_to_builder(*sb2, "    %\n", it);
        print("Block #%\n  road_centroid: %\n  roads:\n%  road_vertices:\n%", it.id, it.road_centroid, builder_to_string(*sb1), builder_to_string(*sb2));
    }

    /*{
        b: Building;
        b.position = .{7.5, 5, 8};
        b.dimensions = .{5, 5, 5};
        spawn(b);
    }*/
    
}
