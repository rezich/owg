game: struct {
    resetting: bool;
    timescale: float = 1;
    camera: Camera3D;
}

game_loop :: inline () {
    using context.entity_storage;
    dt := GetFrameTime();


    // simulate
    handle_input();
    UpdateCamera(*game.camera);


    // draw
    BeginDrawing();
    ClearBackground(DARKGRAY);
    BeginMode3D(game.camera);
    //DrawGrid(20, 1);

    for * roads render(it);
    for * blocks render(it);
    //for * buildings render(it);

    EndMode3D();

    for * roads  render_2d(it);
    for * blocks render_2d(it);

    DrawFPS(0, 0);

    EndDrawing();


    // cleanup
    cleanup_despawning_entities();
    reset_temporary_storage();
}

game_reset :: () {
    log("RESETTING GAME");
    reset_entity_storage();
    game = .{};
    generate_world();
    {
        using game.camera;
        position = .{20, 15, 20};
        target = .{0, 0, 0};
        up = .{0, 1, 0};
        fovy = 45;
        projection = xx CameraProjection.PERSPECTIVE;
    }
}
