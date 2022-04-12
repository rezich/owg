// adapted from https://people.sc.fsu.edu/~jburkardt/c_src/polygon_triangulate/polygon_triangulate.html

angle_degree :: (x1: float, y1: float, x2: float, y2: float, x3: float, y3: float) -> float {
    x, y, value: float;
    x = (x3-x2) * (x1-x2) + (y3-y2) * (y1-y2);
    y = (x3-x2) * (y1-y2) - (y3-y2) * (x1-x2);
    if x == 0 && y == 0 then value = 0;
    else {
        value = atan2(y, x);
        if value < 0 then value = value + PI*2;
        value = 180*value/PI;
    }
    return value;
}

between :: (xa: float, ya: float, xb: float, yb: float, xc: float, yc: float) -> bool {
    xmax, xmin, ymax, ymin: float;
    if !collinear(xa, ya, xb, yb, xc, yc) then return false;
    else if abs(ya-yb) < abs(xa-xb) {
        xmax = max(xa, xb);
        xmin = min(xa, xb);
        return xmin <= xc && xc <= xmax;
    }
    ymax = max(ya, yb);
    ymin = min(ya, yb);
    return ymin <= yc && yc <= ymax;
}

collinear :: (xa: float, ya: float, xb: float, yb: float, xc: float, yc: float) -> bool {
    EPSILON :: 0.0001;
    area, side_ab_sq, side_bc_sq, side_ca_sq, side_max_sq: float;
    area = triangle_area(xa, ya, xb, yb, xc, yc);
    side_ab_sq = pow(xa-xb, 2) + pow(ya-yb, 2);
    side_bc_sq = pow(xb-xc, 2) + pow(yb-yc, 2);
    side_ca_sq = pow(xc-xa, 2) + pow(yc-ya, 2);
    side_max_sq = max(side_ab_sq, max(side_bc_sq, side_ca_sq));
    return side_max_sq <= EPSILON || 2*abs(area) <= EPSILON*side_max_sq;
}

diagonal :: (im1: int, ip1: int, n: int, prev_node: [] int, next_node: [] int, x: [] float, y: [] float) -> bool {
    value1 := in_cone(im1, ip1, n, prev_node, next_node, x, y);
    value2 := in_cone(ip1, im1, n, prev_node, next_node, x, y);
    value3 := diagonalie(im1, ip1, n, next_node, x, y);
    return value1 && value2 && value3;
}

diagonalie :: (im1: int, ip1: int, n: int, next_node: [] int, x: [] float, y: [] float) -> bool {
    first := im1;
    j := first;
    jp1 := next_node[first];
    while true {
        if !(j == im1 || j == ip1 || jp1 == im1 || jp1 == ip1) {
            if intersect(x[im1], y[im1], x[ip1], y[ip1], x[j], y[j], x[jp1], y[jp1]) then return false;
        }
        j = jp1;
        jp1 = next_node[j];
        if j == first then break;
    }
    return true;
}

in_cone :: (im1: int, ip1: int, n: int, prev_node: [] int, next_node: [] int, x: [] float, y: [] float) -> bool {
    im2 := prev_node[im1];
    i := next_node[im1];
    t1 := triangle_area(x[im1], y[im1], x[i], y[i], x[im2], y[im2]);
    if (0 <= t1) {
        t2 := triangle_area(x[im1], y[im1], x[ip1], y[ip1], x[im2], y[im2]);
        t3 := triangle_area(x[ip1], y[ip1], x[im1], y[im1], x[i], y[i]);
        return ((0 < t2) && (0 < t3));
    }
    t4 := triangle_area(x[im1], y[im1], x[ip1], y[ip1], x[i], y[i]);
    t5 := triangle_area(x[ip1], y[ip1], x[im1], y[im1], x[im2], y[im2]);
    return !((0 <= t4) && (0 <= t5));
}

intersect :: (xa: float, ya: float, xb: float, yb: float, xc: float, yc: float, xd: float, yd: float) -> bool {
    if intersect_prop(xa, ya, xb, yb, xc, yc, xd, yd) then return true;
    if between(xa, ya, xb, yb, xc, yc) then return true;
    if between(xa, ya, xb, yb, xd, yd) then return true;
    if between(xc, yc, xd, yd, xa, ya) then return true;
    if between(xc, yc, xd, yd, xb, yb) then return true;
    return false;
}

intersect_prop :: (xa: float, ya: float, xb: float, yb: float, xc: float, yc: float, xd: float, yd: float) -> bool {
    if collinear(xa, ya, xb, yb, xc, yc) then return false;
    if collinear(xa, ya, xb, yb, xd, yd) then return false;
    if collinear(xc, yc, xd, yd, xa, ya) then return false;
    if collinear(xc, yc, xd, yd, xb, yb) then return false;
    v1 := 0 < triangle_area(xa, ya, xb, yb, xc, yc);
    v2 := 0 < triangle_area(xa, ya, xb, yb, xd, yd);
    v3 := 0 < triangle_area(xc, yc, xd, yd, xa, ya);
    v4 := 0 < triangle_area(xc, yc, xd, yd, xb, yb);
    return (v1 ^ v2) && (v3 ^ v4);
}

polygon_area :: (n: int, x: [] float, y: [] float) -> float {
    area: float = 0;
    im1 := n-1;
    for 0..n-1 {
        area = area + x[im1]*y[it] - x[it]*y[im1];
        im1 = it;
    }
    return abs(area)*0.5;
}

//polygon_triangulate :: (n: int, x: [] float, y: [] float) -> 
block_triangluate :: (using block: *Block) {
    log("--------------------------------------");
    for vertices {
        log(" %", it);
    }
    local_vertices: [..] Vector3;
    array_copy(*local_vertices, vertices); defer array_free(local_vertices);
    // bubble_sort (can't use bubble_sort directly Because No Closures)
    {
        count := local_vertices.count;
        last_j := count-2;
        first_j := 0;
        while true {
            latest_swap := -1;
            first_swap  := -1;
            for j : first_j..last_j {
                a := local_vertices[j];
                b := local_vertices[j+1];
                if compare_vertices_rotationally(b, a, centroid) {
                    local_vertices[j]   = b;
                    local_vertices[j+1] = a;
                    latest_swap = j;
                    if first_swap == -1  first_swap = j;
                }
            }
            if latest_swap == -1 break;
            last_j = latest_swap - 1;
            first_j = max(first_swap-1, 0);
        }
    }
    log("---");
    EPSILON :: 0.0001;
    assert(local_vertices.count >= 3);
    array_reset(*triangles);
    x: [..] float;
    y: [..] float;
    for local_vertices {
        array_add(*x, it.x);
        array_add(*y, it.z);
    }
    // consecutive vertices cannot be equal
    node_m1 := vertices.count-1;
    for 0..local_vertices.count-1 {
        if local_vertices[node_m1].x == local_vertices[it].x && local_vertices[node_m1].z == local_vertices[it].z then assert(false);
        node_m1 = it;
    }
    // no node can be the vertex of an angle less than absolute EPSILON
    node1 := local_vertices.count-1;
    for node2: 0..local_vertices.count-1 {
        node3 := (node2+1) % local_vertices.count;
        angle := angle_degree(
            x[node1], y[node1],
            x[node2], y[node2],
            x[node3], y[node3]
        );
        if abs(angle) <= EPSILON {
            log("Error!! % % % %", abs(angle), node1, node2, node3);
            return;
        }
        log("all good % % % %", abs(angle), node1, node2, node3);
        node1 = node2;
    }
    area := polygon_area(local_vertices.count, x, y);
    log("area: %", area);
    assert(area > 0);
    prev_node: [..] int;
    next_node: [..] int;
    for 0..local_vertices.count-1 {
        array_add(*prev_node, ifx it == 0 then local_vertices.count-1 else it-1);
        array_add(*next_node, ifx it == local_vertices.count-1 then 0 else it+1);
    }
    ear: [..] bool;
    for 0..local_vertices.count-1 array_add(*ear, diagonal(prev_node[it], next_node[it], local_vertices.count, prev_node, next_node, x, y));
    triangle_num := 0;
    i2 := 0;
    while triangle_num < local_vertices.count-3 {
        log("% < %", triangle_num, local_vertices.count-3);
        if ear[i2] {
            i3 := next_node[i2];
            i4 := next_node[i3];
            i1 := prev_node[i2];
            i0 := prev_node[i1];
            next_node[i1] = i3;
            prev_node[i3] = i1;
            ear[i1] = diagonal(i0, i3, local_vertices.count, prev_node, next_node, x, y);
            ear[i3] = diagonal(i1, i4, local_vertices.count, prev_node, next_node, x, y);
            array_add(*triangles, tri(i3, i1, i2));
            triangle_num += 1;
        }
        i2 = next_node[i2];
    }
    i3 := next_node[i2];
    i1 := prev_node[i2];
    array_add(*triangles, tri(i3, i1, i2));
    triangle_num += 1;
}

triangle_area :: (xa: float, ya: float, xb: float, yb: float, xc: float, yc: float) -> float {
    return 0.5 * ((xb-xa)*(yc-ya) - (xc-xa)*(yb-ya));
}


