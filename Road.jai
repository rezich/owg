Road :: struct {
    id: int;
    start: Vector3;
    end: Vector3;
    width: float;
    display_width: float;
    left_start_vertices: [..] Vector3;
    left_end_vertices: [..] Vector3;
    right_start_vertices: [..] Vector3;
    right_end_vertices: [..] Vector3;
    //mesh: Mesh;
    //model: Model;
}

roads: Bucket_Array(Road, 1000, true);

spawn :: (using road: Road) -> *Road {
    new_road := road;
    new_road.id = roads.count;
    return bucket_array_find_pointer(*roads, bucket_array_add(*roads, new_road));
}

simulate :: (using road: *Road, dt: float) {
    display_width_prev := display_width;
    display_width = lerp(display_width, width, 10*dt);
    //if display_width_prev != display_width then recalculate(road);
}

render :: (using road: *Road) {
    DrawLine3D(start, end, GRAY);

    /*length := cast(int) floor(distance(xy(start.x, start.z), xy(end.x, end.z)));
    theta := atan2(end.z-start.z, end.x-start.x) + PI/2;
    offset := xyz(cos(theta)*(display_width/2), 0, sin(theta)*(display_width/2));*/
    /*for 0..length
    {
        p := lerp(start, end, cast(float) it / cast(float) length);
        DrawLine3D(p+offset, p-offset, MAGENTA);
    }*/

    //DrawLine3D(start+offset, end+offset, DARKGRAY);
    //DrawLine3D(start-offset, end-offset, DARKGRAY);

    /*left_vertices: [..] Vector3;
    right_vertices: [..] Vector3;
    for left_start_vertices array_add(*left_vertices, it);
    for left_end_vertices array_add(*left_vertices, it);
    for right_start_vertices array_add(*right_vertices, it);
    for right_end_vertices array_add(*right_vertices, it);
    for 0..left_vertices.count-2 DrawLine3D(left_vertices[it], left_vertices[it+1], .{0,255,255,255});
    for 0..right_vertices.count-2 DrawLine3D(right_vertices[it], right_vertices[it+1], .{255,255,0,255});
    array_free(left_vertices);
    array_free(right_vertices);*/
    
    if left_start_vertices.count>0 {
        for 0..left_start_vertices.count-1 {
            a := left_start_vertices[it];
            b := ifx it+1 == left_start_vertices.count then ((start + end) * 0.5) else left_start_vertices[it+1];
            DrawLine3D(a, b, RED);
        }
    }
    if left_end_vertices.count>0 {
        for 0..left_end_vertices.count-1 {
            a := left_end_vertices[it];
            b := ifx it+1 == left_end_vertices.count then ((start + end) * 0.5) else left_end_vertices[it+1];
            DrawLine3D(a, b, YELLOW);
        }
    }
    if right_start_vertices.count>0 {
        for 0..right_start_vertices.count-1 {
            a := right_start_vertices[it];
            b := ifx it+1 == right_start_vertices.count then ((start + end) * 0.5) else right_start_vertices[it+1];
            DrawLine3D(a, b, LIME);
        }
    }
    if right_end_vertices.count>0 {
        for 0..right_end_vertices.count-1 {
            a := right_end_vertices[it];
            b := ifx it+1 == right_end_vertices.count then ((start + end) * 0.5) else right_end_vertices[it+1];
            DrawLine3D(a, b, SKYBLUE);
        }
    }
    //DrawSphereWires(end, 0.25, 4, 4, RED);
    ray: Ray;
    ray.position = start;
    ray.direction = end-start;
    //DrawRay(ray, RED);

}

render_2d :: (using road: *Road) {
    midpoint := ((start + end) * 0.5) + .{0, 0.25, 0};
    cstr := tcprint("%", id);
    pos := GetWorldToScreen(midpoint, game.camera) - MeasureTextEx(the_font, cstr, xx the_font.baseSize, 1)*0.5;
    //DrawTextEx(the_font, cstr, pos, xx the_font.baseSize, 1, RED);
}

SIDE_LENGTH :: 1000;

get_left_side :: (using road: *Road) -> Line_Segment {
    length := cast(int) floor(distance(xy(start.x, start.z), xy(end.x, end.z)));
    theta := atan2(end.z-start.z, end.x-start.x) + PI/2;
    offset := xyz(cos(theta)*(width/2), 0, sin(theta)*(width/2));
    return seg(start+offset, end+offset);
}
get_right_side :: (using road: *Road) -> Line_Segment {
    length := cast(int) floor(distance(xy(start.x, start.z), xy(end.x, end.z)));
    theta := atan2(end.z-start.z, end.x-start.x) + PI/2;
    offset := xyz(cos(theta)*(width/2), 0, sin(theta)*(width/2));
    return seg(start-offset, end-offset);
}
get_left_side_infinity :: (using road: *Road) -> Line_Segment {
    length := cast(int) floor(distance(xy(start.x, start.z), xy(end.x, end.z)));
    theta := atan2(end.z-start.z, end.x-start.x) + PI/2;
    offset := xyz(cos(theta)*(width/2), 0, sin(theta)*(width/2));
    new_start := start+offset;
    new_end := end+offset;
    new_theta := atan2(new_end.z-new_start.z, new_end.x-new_start.x);
    final_start := new_start + xyz(cos(new_theta)*-SIDE_LENGTH, 0, sin(new_theta)*-SIDE_LENGTH);
    final_end := new_end + xyz(cos(new_theta)*SIDE_LENGTH, 0, sin(new_theta)*SIDE_LENGTH);
    return seg(final_start, final_end);
}
get_right_side_infinity :: (using road: *Road) -> Line_Segment {
    length := cast(int) floor(distance(xy(start.x, start.z), xy(end.x, end.z)));
    theta := atan2(end.z-start.z, end.x-start.x) + PI/2;
    offset := xyz(cos(theta)*(width/2), 0, sin(theta)*(width/2));
    new_start := start-offset;
    new_end := end-offset;
    new_theta := atan2(new_end.z-new_start.z, new_end.x-new_start.x);
    final_start := new_start + xyz(cos(new_theta)*-SIDE_LENGTH, 0, sin(new_theta)*-SIDE_LENGTH);
    final_end := new_end + xyz(cos(new_theta)*SIDE_LENGTH, 0, sin(new_theta)*SIDE_LENGTH);
    return seg(final_start, final_end);
}

// https://www.codeproject.com/Articles/226569/Drawing-polylines-by-tessellation
