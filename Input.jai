handle_input :: inline () {
    mouse_position := GetMousePosition();
    if IsKeyPressed(xx KeyboardKey.SPACE) {
        SetCameraMode(game.camera, xx CameraMode.ORBITAL);
    }
}
