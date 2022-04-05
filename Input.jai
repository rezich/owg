handle_input :: inline () {
    using game;
    mouse_position := GetMousePosition();
    if IsKeyPressed(xx KeyboardKey.SPACE) {
        SetCameraMode(camera, xx CameraMode.ORBITAL);
    }
    if IsKeyPressed(xx KeyboardKey.F1) {
        if mode == .SPAWN_ROAD_NODE then mode = .DEFAULT; else mode = .SPAWN_ROAD_NODE;
    };
    if IsKeyPressed(xx KeyboardKey.F2) {
        selected_road_node = null;
        if mode == .CONNECT_ROAD_NODE_FROM then mode = .DEFAULT;
        else mode = .CONNECT_ROAD_NODE_FROM;
    }
    if IsKeyPressed(xx KeyboardKey.F3) {
        selected_road_node = null;
        if mode == .REPOSITION_ROAD_NODE then mode = .DEFAULT;
        else mode = .REPOSITION_ROAD_NODE;
    }

    if IsMouseButtonPressed(xx MouseButton.LEFT) {
        collision: RayCollision;
        if mode == {
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
                        GetMouseRay(GetMousePosition(), camera),
                        it.position + Vector3.{-0.5,0,-0.5},
                        it.position + Vector3.{0.5,0,-0.5},
                        it.position + Vector3.{0.5,0,0.5},
                        it.position + Vector3.{-0.5,0,0.5}
                    );
                    if collision.hit {
                        selected_road_node = it;
                        mode = .CONNECT_ROAD_NODE_TO;
                        break;
                    }
                }
            case .CONNECT_ROAD_NODE_TO;
                for * road_nodes {
                    if it == selected_road_node then continue;
                    collision = GetRayCollisionQuad(
                        GetMouseRay(GetMousePosition(), camera),
                        it.position + Vector3.{-0.5,0,-0.5},
                        it.position + Vector3.{0.5,0,-0.5},
                        it.position + Vector3.{0.5,0,0.5},
                        it.position + Vector3.{-0.5,0,0.5}
                    );
                    if collision.hit {
                        success := connect_road_nodes(selected_road_node, it);
                        if !success then log("Failed to connect roads, connection already exists");
                        selected_road_node = null;
                        mode = .CONNECT_ROAD_NODE_FROM;
                        break;
                    }
                }
            case .REPOSITION_ROAD_NODE;
                for * road_nodes {
                    collision = GetRayCollisionQuad(
                        GetMouseRay(GetMousePosition(), camera),
                        it.position + Vector3.{-0.5,0,-0.5},
                        it.position + Vector3.{0.5,0,-0.5},
                        it.position + Vector3.{0.5,0,0.5},
                        it.position + Vector3.{-0.5,0,0.5}
                    );
                    if collision.hit {
                        selected_road_node = it;
                        break;
                    }
                }
        }
    }
    if IsMouseButtonDown(xx MouseButton.LEFT) {
        if mode == {
            case .REPOSITION_ROAD_NODE;
                if !selected_road_node then return;
                collision := get_3d_cursor_collision();
                reposition_road_node(selected_road_node, collision.point);
        }
    }
    if IsMouseButtonReleased(xx MouseButton.LEFT) {
        if mode == {
            case .REPOSITION_ROAD_NODE;
                selected_road_node = null;
        }
    }
}
