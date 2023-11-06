#pragma once

#include <cmath>
#include <cassert>
#include <cstdint>

#include <vector>
#include <string>
#include <memory>
#include <iostream>

typedef double Float;

#define HOST_DEVICE_ENTRY __host__ __device__

namespace sf
{

class RenderWindow;
class Vertex;
class Text;
class Font;
class Sprite;
class Texture;

}

namespace man
{

class View;
class Renderer;

template<class T>
class Vector2;
typedef Vector2<Float> Float2;
typedef Vector2<int32_t> Int2;

} // rw
