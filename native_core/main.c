#define UNICODE
#define _UNICODE
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <mmsystem.h>
#include <GL/gl.h>
#include <math.h>
#include <stdio.h>

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "opengl32.lib")
#pragma comment(lib, "winmm.lib")

#define M_PI 3.14159265358979323846f

// -------------------------------------------------------------
// SPORTSMAN'S QUEST: NATIVE SUB-1MB STANDALONE HUNTING ENGINE
// Zero External Dependencies • Zero Bloat • Direct Win32 & OpenGL
// -------------------------------------------------------------

typedef struct {
    float x, y, z;
} Vec3;

typedef struct {
    Vec3 pos;
    Vec3 dir;
    int alive;
    float bleed_time;
    float alert;
} Deer;

typedef struct {
    Vec3 pos;
    float angle;
    int state; // 0 = swim, 1 = fly, 2 = falling, 3 = dead
    float vel_y;
} Duck;

static HDC hDC;
static HGLRC hRC;
static HWND hWnd;
static int running = 1;

// Hunter State
static Vec3 hunter_pos = { 15.0f, 1.8f, -10.0f };
static float hunter_yaw = 0.0f;
static float hunter_pitch = 0.0f;
static int current_weapon = 0; // 0 = Rifle, 1 = Roper Shotgun (Birdshot), 2 = Binoculars
static int roper_ammo = 4;
static int zero_range = 100; // 100m, 200m, 300m
static int is_aiming = 0;
static char hud_text[256];

// Wildlife
#define MAX_DEER 4
#define MAX_DUCKS 6
static Deer deer_herd[MAX_DEER];
static Duck duck_flock[MAX_DUCKS];

// Procedural Heightmap (Whispering Pines Basin)
static float get_terrain_height(float x, float z) {
    float dist_from_lake = sqrtf(x * x + z * z);
    float lake_basin = (dist_from_lake < 65.0f) ? -3.5f + (dist_from_lake / 65.0f) * 3.5f : 0.0f;
    float ridges = sinf(x * 0.045f) * cosf(z * 0.045f) * 4.5f + sinf(x * 0.12f) * 1.5f;
    float h = lake_basin + ridges;
    return (h < -0.2f) ? -0.2f : h;
}

// Procedural Audio Synthesizer (Direct Win32 PCM waveOut)
static void play_synth_sound(int type) {
    #define SAMPLE_RATE 11025
    #define NUM_SAMPLES 5500
    static short pcm[NUM_SAMPLES];
    static WAVEHDR header;
    static HWAVEOUT hWaveOut = 0;

    if (!hWaveOut) {
        WAVEFORMATEX wfx;
        wfx.wFormatTag = WAVE_FORMAT_PCM;
        wfx.nChannels = 1;
        wfx.nSamplesPerSec = SAMPLE_RATE;
        wfx.nAvgBytesPerSec = SAMPLE_RATE * 2;
        wfx.nBlockAlign = 2;
        wfx.wBitsPerSample = 16;
        wfx.cbSize = 0;
        waveOutOpen(&hWaveOut, WAVE_MAPPER, &wfx, 0, 0, CALLBACK_NULL);
    }

    for (int i = 0; i < NUM_SAMPLES; i++) {
        float t = (float)i / SAMPLE_RATE;
        float amp = 1.0f - ((float)i / NUM_SAMPLES);
        float sample = 0.0f;
        
        if (type == 0) { // Rifle gunshot crack + acoustic echo
            float noise = ((float)(rand() % 1000) / 500.0f - 1.0f);
            sample = noise * expf(-t * 18.0f) * 28000.0f;
        } else if (type == 1) { // Mallard quack
            sample = sinf(2.0f * M_PI * 450.0f * t) * expf(-t * 6.0f) * 18000.0f;
        } else if (type == 2) { // Mechanical click
            sample = ((float)(rand() % 100) / 50.0f - 1.0f) * expf(-t * 150.0f) * 24000.0f;
        }
        pcm[i] = (short)(sample * amp);
    }

    header.lpData = (LPSTR)pcm;
    header.dwBufferLength = NUM_SAMPLES * 2;
    header.dwFlags = 0;
    waveOutPrepareHeader(hWaveOut, &header, sizeof(WAVEHDR));
    waveOutWrite(hWaveOut, &header, sizeof(WAVEHDR));
}

// -------------------------------------------------------------
// FIRE & BALLISTICS
// -------------------------------------------------------------
static void fire_weapon() {
    if (current_weapon == 0) { // .308 Bolt Rifle
        play_synth_sound(0);
        float fwd_x = -sinf(hunter_yaw);
        float fwd_z = -cosf(hunter_yaw);
        
        // Raycast hit check on deer
        for (int i = 0; i < MAX_DEER; i++) {
            if (!deer_herd[i].alive) continue;
            float dx = deer_herd[i].pos.x - hunter_pos.x;
            float dz = deer_herd[i].pos.z - hunter_pos.z;
            float dist = sqrtf(dx * dx + dz * dz);
            float dot = (dx * fwd_x + dz * fwd_z) / dist;
            if (dot > 0.985f && dist < 350.0f) {
                deer_herd[i].alive = 0;
                snprintf(hud_text, sizeof(hud_text), "[HARVEST CLAIMABLE] Whitetail Deer struck in Heart at %.1fm! Press E", dist);
                return;
            }
        }
        snprintf(hud_text, sizeof(hud_text), "[Rifle] Shot fired! Echoing across valley (Zero: %dm)", zero_range);
    } else if (current_weapon == 1) { // Roper Repeating Shotgun (Birdshot)
        if (roper_ammo <= 0) {
            play_synth_sound(2);
            snprintf(hud_text, sizeof(hud_text), "[Roper Shotgun] Cylinder empty (0/4). Press R to reload!");
            return;
        }
        roper_ammo--;
        play_synth_sound(0);
        
        // Hit check on flying / swimming ducks
        float fwd_x = -sinf(hunter_yaw);
        float fwd_z = -cosf(hunter_yaw);
        for (int i = 0; i < MAX_DUCKS; i++) {
            if (duck_flock[i].state == 3) continue;
            float dx = duck_flock[i].pos.x - hunter_pos.x;
            float dy = duck_flock[i].pos.y - hunter_pos.y;
            float dz = duck_flock[i].pos.z - hunter_pos.z;
            float dist = sqrtf(dx * dx + dy * dy + dz * dz);
            float dot = (dx * fwd_x + dz * fwd_z) / sqrtf(dx * dx + dz * dz);
            if (dot > 0.92f && dist < 75.0f) {
                duck_flock[i].state = 2; // Falling splashdown
                snprintf(hud_text, sizeof(hud_text), "[WATERFOWL DOWN] Mallard folded mid-air! Falling to water.");
                return;
            }
        }
        snprintf(hud_text, sizeof(hud_text), "[Roper Shotgun] Fired 24 Birdshot pellets! (%d/4)", roper_ammo);
    }
}

// -------------------------------------------------------------
// WIN32 WINDOW & INPUT
// -------------------------------------------------------------
LRESULT CALLBACK WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
        case WM_CLOSE: running = 0; DestroyWindow(hWnd); return 0;
        case WM_DESTROY: PostQuitMessage(0); return 0;
        case WM_LBUTTONDOWN: fire_weapon(); return 0;
        case WM_RBUTTONDOWN: is_aiming = 1; return 0;
        case WM_RBUTTONUP: is_aiming = 0; return 0;
        case WM_KEYDOWN:
            if (wParam == VK_ESCAPE) running = 0;
            if (wParam == '1') { current_weapon = 0; snprintf(hud_text, sizeof(hud_text), "[Equipped] .308 Bolt-Action Rifle (Zero: %dm)", zero_range); }
            if (wParam == '2') { current_weapon = 1; snprintf(hud_text, sizeof(hud_text), "[Equipped] 1866 Roper Shotgun (Birdshot %d/4)", roper_ammo); }
            if (wParam == '3') { current_weapon = 2; snprintf(hud_text, sizeof(hud_text), "[Equipped] 8x42 Optical Rangefinder Binoculars"); }
            if (wParam == 'R') { roper_ammo = 4; play_synth_sound(2); snprintf(hud_text, sizeof(hud_text), "[Roper Shotgun] Revolving cylinder loaded to 4/4."); }
            if (wParam == 'F') { zero_range = (zero_range == 100) ? 200 : ((zero_range == 200) ? 300 : 100); play_synth_sound(2); snprintf(hud_text, sizeof(hud_text), "[Optics] Scope zeroed to: %dm", zero_range); }
            return 0;
    }
    return DefWindowProc(hWnd, msg, wParam, lParam);
}

// -------------------------------------------------------------
// OPENGL 3D RENDERER
// -------------------------------------------------------------
static void init_gl() {
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glClearColor(0.45f, 0.65f, 0.85f, 1.0f); // Sky blue
    
    // Wildlife spawn
    for (int i = 0; i < MAX_DEER; i++) {
        deer_herd[i].pos.x = 25.0f + (float)(i * 8);
        deer_herd[i].pos.z = -45.0f + (float)(i * 4);
        deer_herd[i].pos.y = get_terrain_height(deer_herd[i].pos.x, deer_herd[i].pos.z);
        deer_herd[i].alive = 1;
    }
    for (int i = 0; i < MAX_DUCKS; i++) {
        duck_flock[i].pos.x = sinf((float)i) * 25.0f;
        duck_flock[i].pos.z = cosf((float)i) * 25.0f;
        duck_flock[i].pos.y = 0.0f;
        duck_flock[i].state = 0;
        duck_flock[i].angle = (float)i * 1.05f;
    }
    snprintf(hud_text, sizeof(hud_text), "SPORTSMAN'S QUEST (SUB-1MB NATIVE) • WASD: Move | LMB: Fire | 1/2: Guns | F: Zero");
}

static void draw_scene() {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
    // Perspective math (FOV: 75 deg or 22 deg when aiming)
    float fov = is_aiming ? 24.0f : 75.0f;
    float aspect = 1280.0f / 720.0f;
    float f = 1.0f / tanf(fov * (M_PI / 360.0f));
    float m[16] = {0};
    m[0] = f / aspect; m[5] = f; m[10] = -1.002f; m[11] = -1.0f; m[14] = -0.2f;
    glLoadMatrixf(m);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glRotatef(-hunter_pitch, 1, 0, 0);
    glRotatef(-hunter_yaw * (180.0f / M_PI), 0, 1, 0);
    glTranslatef(-hunter_pos.x, -hunter_pos.y, -hunter_pos.z);

    // 1. Draw Procedural Lake Surface
    glColor4f(0.18f, 0.42f, 0.58f, 0.8f);
    glBegin(GL_QUADS);
    glVertex3f(-250, 0.0f, -250);
    glVertex3f( 250, 0.0f, -250);
    glVertex3f( 250, 0.0f,  250);
    glVertex3f(-250, 0.0f,  250);
    glEnd();

    // 2. Draw Procedural Terrain Grid (Whispering Pines)
    glBegin(GL_TRIANGLES);
    for (float z = -200; z < 200; z += 6.0f) {
        for (float x = -200; x < 200; x += 6.0f) {
            float y00 = get_terrain_height(x, z);
            float y10 = get_terrain_height(x + 6.0f, z);
            float y01 = get_terrain_height(x, z + 6.0f);
            float y11 = get_terrain_height(x + 6.0f, z + 6.0f);
            
            // Color based on elevation and slope
            if (y00 < 0.2f) glColor3f(0.25f, 0.20f, 0.12f); // Shoreline mud
            else glColor3f(0.24f, 0.38f, 0.18f); // Pine grass

            glVertex3f(x, y00, z);
            glVertex3f(x + 6.0f, y10, z);
            glVertex3f(x, y01, z + 6.0f);

            glVertex3f(x + 6.0f, y10, z);
            glVertex3f(x + 6.0f, y11, z + 6.0f);
            glVertex3f(x, y01, z + 6.0f);
        }
    }
    glEnd();

    // 3. Draw Wildlife: Whitetail Deer
    for (int i = 0; i < MAX_DEER; i++) {
        if (!deer_herd[i].alive) continue;
        glPushMatrix();
        glTranslatef(deer_herd[i].pos.x, deer_herd[i].pos.y + 0.6f, deer_herd[i].pos.z);
        glColor3f(0.48f, 0.30f, 0.16f); // Buck coat
        
        // Body Box
        glBegin(GL_QUADS);
        glVertex3f(-0.3f, -0.4f, -0.8f); glVertex3f(0.3f, -0.4f, -0.8f);
        glVertex3f( 0.3f,  0.4f, -0.8f); glVertex3f(-0.3f,  0.4f, -0.8f);
        glVertex3f(-0.3f, -0.4f,  0.8f); glVertex3f(0.3f, -0.4f,  0.8f);
        glVertex3f( 0.3f,  0.4f,  0.8f); glVertex3f(-0.3f,  0.4f,  0.8f);
        glEnd();
        glPopMatrix();
    }

    // 4. Draw Wildlife: Mallards
    for (int i = 0; i < MAX_DUCKS; i++) {
        glPushMatrix();
        glTranslatef(duck_flock[i].pos.x, duck_flock[i].pos.y + 0.15f, duck_flock[i].pos.z);
        glColor3f(0.1f, 0.45f, 0.2f); // Mallard green head
        glBegin(GL_TRIANGLES);
        glVertex3f(0.0f, 0.25f, -0.2f);
        glVertex3f(-0.25f, 0.0f, 0.25f);
        glVertex3f( 0.25f, 0.0f, 0.25f);
        glEnd();
        glPopMatrix();
    }
}

// -------------------------------------------------------------
// MAIN ENTRY
// -------------------------------------------------------------
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    WNDCLASSEX wc = {sizeof(WNDCLASSEX), CS_OWNDC, WndProc, 0, 0, hInstance, 0, 
                     LoadCursor(NULL, IDC_CROSS), 0, 0, L"SportsmanEngine", 0};
    RegisterClassEx(&wc);

    hWnd = CreateWindowEx(0, L"SportsmanEngine", L"Sportsman's Quest [Sub-1MB Native Engine]", 
                          WS_OVERLAPPEDWINDOW | WS_VISIBLE, 100, 100, 1280, 720, 0, 0, hInstance, 0);

    hDC = GetDC(hWnd);
    PIXELFORMATDESCRIPTOR pfd = {sizeof(pfd), 1, PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER, 
                                 PFD_TYPE_RGBA, 32, 0,0,0,0,0,0, 0,0,0,0,0,0,0, 24, 8, 0, PFD_MAIN_PLANE, 0, 0,0,0};
    SetPixelFormat(hDC, ChoosePixelFormat(hDC, &pfd), &pfd);
    hRC = wglCreateContext(hDC);
    wglMakeCurrent(hDC, hRC);

    init_gl();

    MSG msg;
    POINT last_cursor;
    GetCursorPos(&last_cursor);

    while (running) {
        while (PeekMessage(&msg, 0, 0, 0, PM_REMOVE)) {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }

        // WASD Movement
        float speed = (GetAsyncKeyState(VK_SHIFT) & 0x8000) ? 0.35f : 0.16f;
        float fwd_x = -sinf(hunter_yaw);
        float fwd_z = -cosf(hunter_yaw);
        float right_x = cosf(hunter_yaw);
        float right_z = -sinf(hunter_yaw);

        if (GetAsyncKeyState('W') & 0x8000) { hunter_pos.x += fwd_x * speed; hunter_pos.z += fwd_z * speed; }
        if (GetAsyncKeyState('S') & 0x8000) { hunter_pos.x -= fwd_x * speed; hunter_pos.z -= fwd_z * speed; }
        if (GetAsyncKeyState('A') & 0x8000) { hunter_pos.x -= right_x * speed; hunter_pos.z -= right_z * speed; }
        if (GetAsyncKeyState('D') & 0x8000) { hunter_pos.x += right_x * speed; hunter_pos.z += right_z * speed; }

        hunter_pos.y = get_terrain_height(hunter_pos.x, hunter_pos.z) + 1.8f;

        // Mouse look
        if (GetForegroundWindow() == hWnd) {
            POINT current_cursor;
            GetCursorPos(&current_cursor);
            float dx = (float)(current_cursor.x - last_cursor.x);
            float dy = (float)(current_cursor.y - last_cursor.y);
            hunter_yaw += dx * 0.0035f;
            hunter_pitch += dy * 0.25f;
            if (hunter_pitch > 80.0f) hunter_pitch = 80.0f;
            if (hunter_pitch < -80.0f) hunter_pitch = -80.0f;
            SetCursorPos(600, 400);
            last_cursor.x = 600; last_cursor.y = 400;
        }

        // Update ducks
        for (int i = 0; i < MAX_DUCKS; i++) {
            if (duck_flock[i].state == 0) { // Swimming
                duck_flock[i].angle += 0.015f;
                duck_flock[i].pos.x = sinf(duck_flock[i].angle) * 35.0f;
                duck_flock[i].pos.z = cosf(duck_flock[i].angle) * 35.0f;
            } else if (duck_flock[i].state == 2) { // Falling to water
                duck_flock[i].vel_y -= 0.02f;
                duck_flock[i].pos.y += duck_flock[i].vel_y;
                if (duck_flock[i].pos.y <= 0.0f) {
                    duck_flock[i].pos.y = 0.0f;
                    duck_flock[i].state = 3; // Float for claim
                }
            }
        }

        draw_scene();
        SwapBuffers(hDC);
        SetWindowTextA(hWnd, hud_text);
        Sleep(16); // 60 FPS lock
    }

    wglMakeCurrent(0, 0);
    wglDeleteContext(hRC);
    ReleaseDC(hWnd, hDC);
    return 0;
}
