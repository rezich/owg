handle_input :: inline () {
    mouse_position := GetMousePosition();
    if IsKeyPressed(xx KeyboardKey.SPACE) {
        SetCameraMode(game.camera, xx CameraMode.ORBITAL);
    }
    if IsKeyPressed(xx KeyboardKey.F1) {
        if game.mode == .SPAWN_ROAD_NODE then game.mode = .DEFAULT; else game.mode = .SPAWN_ROAD_NODE;
    };
    if IsKeyPressed(xx KeyboardKey.F2) {
        if game.mode == .CONNECT_ROAD_NODE_FROM then game.mode = .DEFAULT;
        else {
            game.mode = .CONNECT_ROAD_NODE_FROM;
            game.road_node_from = null;
            game.road_node_to = null;
        }
    }

    if IsMouseButtonPressed(xx MouseButton.LEFT) {
        collision: RayCollision;
        if game.mode == {
            case .SPAWN_ROAD_NODE;
                collision := get_3d_cursor_collision();
                if collision.hit {
                    node: Road_Node;
                    node.position = collision.point;
                    spawn(node);
                }
            case .CONNECT_ROAD_NODE_FROM;
                for * road_nodes {
                    collision = GetRayCollisionQuad(
                        GetMouseRay(GetMousePosition(), game.camera),
                        it.position + Vector3.{-0.5,0,-0.5},
                        it.position + Vector3.{0.5,0,-0.5},
                        it.position + Vector3.{0.5,0,0.5},
                        it.position + Vector3.{-0.5,0,0.5}
                    );
                    if collision.hit {
                        game.road_node_from = it;
                        game.mode = .CONNECT_ROAD_NODE_TO;
                    }
                }
            case .CONNECT_ROAD_NODE_TO;
                for * road_nodes {
                    if it == game.road_node_from then continue;
                    collision = GetRayCollisionQuad(
                        GetMouseRay(GetMousePosition(), game.camera),
                        it.position + Vector3.{-0.5,0,-0.5},
                        it.position + Vector3.{0.5,0,-0.5},
                        it.position + Vector3.{0.5,0,0.5},
                        it.position + Vector3.{-0.5,0,0.5}
                    );
                    if collision.hit {
                        game.road_node_to = it;
                        success := connect_road_nodes(game.road_node_from, game.road_node_to);
                        if !success then log("Failed to connect roads, connection already exists");
                        game.mode = .DEFAULT;
                    }
                }
        }
    }
}
