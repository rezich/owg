main :: () {
    window_title := to_c_string("owg");
    InitWindow(800, 600, window_title);
    SetTargetFPS(60);
    SetMouseCursor(xx MouseCursor.CROSSHAIR);
    the_font = LoadFont(tcprint("assets/font/mecha.png"));

    game.resetting = true;
    while game.resetting {
        game_reset();
        while !WindowShouldClose() {
            game_loop();
            if IsKeyPressed(xx KeyboardKey.F5) { game.resetting = true; break; }
        }
    }
    CloseWindow();
}

the_font: Font;

#load "Game.jai";
#load "Input.jai";
#load "Entity.jai";
#load "Worldgen.jai";
#load "Util.jai";

#import "Math";
#import "Sort";
#import "Basic";
#import "Random";
#import "Bucket_Array";

#import "Entity_Storage";
#import "Raylib-Jai";
