game: struct {
    resetting: bool;
    timescale: float = 1;
    camera: Camera3D;
    mode: enum {
        DEFAULT;
        SPAWN_ROAD_NODE;
        CONNECT_ROAD_NODE_FROM;
        CONNECT_ROAD_NODE_TO;
        REPOSITION_ROAD_NODE;
    };
    selected_road_node: *Road_Node;
}

game_loop :: inline () {
    using context.entity_storage;
    dt := GetFrameTime();


    // simulate
    handle_input();
    UpdateCamera(*game.camera);

    for * roads simulate(it, dt);
    for * blocks simulate(it, dt);


    // draw
    BeginDrawing();
    ClearBackground(.{24,24,24,255});
    BeginMode3D(game.camera);
    //DrawGrid(20, 1);

    draw_cursor();

    for * roads render(it);
    for * blocks render(it);
    //for * buildings render(it);
    for * road_nodes render(it);

    EndMode3D();

    for * roads  render_2d(it);
    for * blocks render_2d(it);
    for * road_nodes render_2d(it);

    DrawFPS(WINDOW_WIDTH-80, 4);
    DrawTextEx(the_font, tcprint("%", game.mode), .{2,0}, xx (the_font.baseSize*2), 1, RAYWHITE);

    EndDrawing();


    // cleanup
    cleanup_despawning_entities();
    reset_temporary_storage();
}

game_reset :: () {
    log("RESETTING GAME");
    reset_entity_storage();
    game = .{};
    bucket_array_reset(*roads);
    bucket_array_reset(*road_nodes);
    bucket_array_reset(*blocks);
    //generate_world();
    {
        using game.camera;
        position = .{20, 15, 20};
        target = .{0, 0, 0};
        up = .{0, 1, 0};
        fovy = 45;
        projection = xx CameraProjection.PERSPECTIVE;
    }
}

get_3d_cursor_collision :: () -> RayCollision {
    BOUND :: 1000;
    return GetRayCollisionQuad(GetMouseRay(GetMousePosition(), game.camera), .{-BOUND,0,-BOUND}, .{-BOUND,0,BOUND}, .{BOUND,0,BOUND}, .{BOUND,0,-BOUND});
}

draw_cursor :: () {
    CURSOR_SIZE :: 0.5;
    if game.mode == {
        case .DEFAULT;
            return;
        case .SPAWN_ROAD_NODE;
            collision := get_3d_cursor_collision();
            if collision.hit {
                DrawCircle3D(collision.point, CURSOR_SIZE, .{1,0,0}, 90, YELLOW);
            }
        case .CONNECT_ROAD_NODE_FROM;
            collision: RayCollision;
            for * road_nodes {
                collision = GetRayCollisionQuad(
                    GetMouseRay(GetMousePosition(), game.camera),
                    it.position + Vector3.{-0.5,0,-0.5},
                    it.position + Vector3.{0.5,0,-0.5},
                    it.position + Vector3.{0.5,0,0.5},
                    it.position + Vector3.{-0.5,0,0.5}
                );
                if collision.hit {
                    DrawCircle3D(it.position, 0.6, .{1,0,0}, 90, YELLOW);
                }
            }
        case .CONNECT_ROAD_NODE_TO;
            DrawCircle3D(game.selected_road_node.position, 0.6, .{1,0,0}, 90, YELLOW);
            collision := get_3d_cursor_collision();
            if collision.hit {
                DrawLine3D(game.selected_road_node.position, collision.point, YELLOW);
                for * road_nodes {
                    if it == game.selected_road_node then continue;
                    collision = GetRayCollisionQuad(
                        GetMouseRay(GetMousePosition(), game.camera),
                        it.position + Vector3.{-0.5,0,-0.5},
                        it.position + Vector3.{0.5,0,-0.5},
                        it.position + Vector3.{0.5,0,0.5},
                        it.position + Vector3.{-0.5,0,0.5}
                    );
                    if collision.hit {
                        DrawCircle3D(it.position, 0.6, .{1,0,0}, 90, YELLOW);
                    }
                }
            }
    }
}
