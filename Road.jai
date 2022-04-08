Road :: struct {
    id: int;
    start: Vector3;
    end: Vector3;
    width: float;
    display_width: float;
    left_vertices: [..] Vector3;
    right_vertices: [..] Vector3;
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
    display_width = lerp(display_width, width, 10*dt);
}

render :: (using road: *Road) {
    DrawLine3D(start, end, GRAY);

    length := cast(int) floor(distance(xy(start.x, start.z), xy(end.x, end.z)));
    theta := atan2(end.z-start.z, end.x-start.x) + PI/2;
    offset := xyz(cos(theta)*(display_width/2), 0, sin(theta)*(display_width/2));
    /*for 0..length
    {
        p := lerp(start, end, cast(float) it / cast(float) length);
        DrawLine3D(p+offset, p-offset, MAGENTA);
    }*/
    DrawLine3D(start+offset, end+offset, DARKGRAY);
    DrawLine3D(start-offset, end-offset, DARKGRAY);
    //for left_vertices DrawLine3D()
}

render_2d :: (using road: *Road) {
    midpoint := ((start + end) * 0.5) + .{0, 0.25, 0};
    cstr := tcprint("%", id);
    pos := GetWorldToScreen(midpoint, game.camera) - MeasureTextEx(the_font, cstr, xx the_font.baseSize, 1)*0.5;
    DrawTextEx(the_font, cstr, pos, xx the_font.baseSize, 1, RED);
}

recalculate_start :: (using road: *Road, node: *Road_Node) {
    start = node.position;

}
recalculate_end :: (using road: *Road, node: *Road_Node) {
    end = node.position;
    
}
// https://www.codeproject.com/Articles/226569/Drawing-polylines-by-tessellation
