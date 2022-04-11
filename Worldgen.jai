#load "Road_Node.jai";
#load "Road.jai";
#load "Block.jai";

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
    n0, n1, n2, n3, n4: *Road_Node;
    { node: Road_Node; node.position = .{0,0,0}; n0 = spawn(node); }
    { node: Road_Node; node.position = .{0,0,10}; n1 = spawn(node); }
    { node: Road_Node; node.position = .{10,0,10}; n2 = spawn(node); }
    { node: Road_Node; node.position = .{-10,0,0}; n3 = spawn(node); }
    { node: Road_Node; node.position = .{12,0,8}; n4 = spawn(node); }
    connect_road_nodes(n0, n1);
    connect_road_nodes(n0, n2);
    connect_road_nodes(n3, n0);
    connect_road_nodes(n4, n0);
    connect_road_nodes(n3, n1);
    connect_road_nodes(n2, n4);
    connect_road_nodes(n1, n2);

    /*n0, n1, n2, n3, n4: *Road_Node;
    { node: Road_Node; node.position = .{0,0,0}; n0 = spawn(node); }
    { node: Road_Node; node.position = .{0,0,10}; n1 = spawn(node); }
    { node: Road_Node; node.position = .{10,0,5}; n2 = spawn(node); }
    { node: Road_Node; node.position = .{-10,0,-10}; n3 = spawn(node); }
    { node: Road_Node; node.position = .{-10,0,0}; n4 = spawn(node); }
    connect_road_nodes(n0, n1);
    connect_road_nodes(n1, n2);
    connect_road_nodes(n3, n2);
    connect_road_nodes(n4, n3);
    connect_road_nodes(n4, n0);*/
}
