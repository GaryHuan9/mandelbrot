#include "Renderer.cuh"
#include "View.hpp"

#include <SFML/Window.hpp>
#include <SFML/Graphics.hpp>
#include <SFML/OpenGL.hpp>
#include <cuda_gl_interop.h>
#include <numbers>

void cuda_check(cudaError result)
{
	if (result == cudaSuccess) return;
	throw std::exception(cudaGetErrorString(result));
}

namespace man
{

Renderer::Renderer(const View& view) : view(view), sprite(new sf::Sprite{}), texture(new sf::Texture{})
{

}

__device__
float3 palette(float t, float3 a, float3 b, float3 c, float3 d)
{
	constexpr float Tau = std::numbers::pi * 2.0f;
	float x = a.x + b.x * cos(Tau * (c.x * t + d.x));
	float y = a.y + b.y * cos(Tau * (c.y * t + d.y));
	float z = a.z + b.z * cos(Tau * (c.z * t + d.z));
	return make_float3(x, y, z);
}

__device__
uint32_t convert_channel(float value)
{
	return min((uint32_t)(std::sqrt(value) * 256.0f), 255);
}

__global__
void kernel(Int2 resolution, Float2 view_center, Float2 view_extend, cudaSurfaceObject_t surface)
{
	uint32_t x = blockIdx.x * blockDim.x + threadIdx.x;
	uint32_t y = blockIdx.y * blockDim.y + threadIdx.y;
	if (x >= resolution.x || y >= resolution.y) return;

	Float half_resolution_x = (Float)resolution.x / (Float)2.0;
	Float half_resolution_y = (Float)resolution.y / (Float)2.0;

	Float normal_x = ((Float)x + (Float)0.5 - half_resolution_x) / half_resolution_x;
	Float normal_y = ((Float)y + (Float)0.5 - half_resolution_y) / half_resolution_y;

	Float first_position_x = fma(normal_x, view_extend.x, view_center.x);
	Float first_position_y = fma(normal_y, view_extend.y, view_center.y);

	auto julia_x = (Float)-0.05;
	auto julia_y = (Float)-0.66;

	Float position_x = first_position_x;
	Float position_y = first_position_y;

	uint32_t iteration = 0;

	while (iteration < 1024)
	{
		//		Float next_position_x = first_position_x + position_x * position_x - position_y * position_y;
		//		Float next_position_y = first_position_y + position_x * position_y * (Float)2.0;

		Float next_position_x = julia_x + position_x * position_x - position_y * position_y;
		Float next_position_y = julia_y + position_x * position_y * (Float)2.0;

		Float squared_magnitude = next_position_x * next_position_x + next_position_y * next_position_y;
		if (squared_magnitude >= 4.0f) break;

		position_x = next_position_x;
		position_y = next_position_y;

		++iteration;
	}

	float brightness = (float)iteration / 256.0f;
	brightness = brightness - truncf(brightness);
	uint32_t converted = min((uint32_t)(std::sqrt(brightness) * 256.0f), 255);
	uint32_t value = (converted << 16) | (converted << 8) | converted;

	//	float3 a = make_float3(0.5, 0.5, 0.5);
	//	float3 b = make_float3(0.5, 0.5, 0.5);
	//	float3 c = make_float3(4.0, 4.0, 4.0);
	//	float3 d = make_float3(0.00, 1.0f / 3.0f, 2.0f / 3.0f);
	//	float3 color = palette((float)iteration / 1024.0f, a, b, c, d);
	//	uint32_t value = (convert_channel(color.x) << 16) | (convert_channel(color.y) << 8) | convert_channel(color.z);

	surf2Dwrite<uint32_t>(0xFF000000 | value, surface, x * sizeof(uint32_t), y);
}

void Renderer::recreate_resources(Int2 resolution)
{
	if (graphics_resource != nullptr) cuda_check(cudaGraphicsUnregisterResource(graphics_resource));

	texture->create(resolution.x, resolution.y);
	sprite->setTexture(*texture, true);

	cuda_check(cudaGraphicsGLRegisterImage(
		&graphics_resource, texture->getNativeHandle(),
		GL_TEXTURE_2D, cudaGraphicsRegisterFlagsWriteDiscard));
}

void Renderer::launch_kernels(Int2 resolution, Int2 block_size)
{
	cudaResourceDesc description{ cudaResourceTypeArray };

	cuda_check(cudaGraphicsMapResources(1, &graphics_resource));
	cuda_check(cudaGraphicsSubResourceGetMappedArray(&description.res.array.array, graphics_resource, 0, 0));

	cudaSurfaceObject_t surface;
	cuda_check(cudaCreateSurfaceObject(&surface, &description));

	Int2 block_count = (resolution + block_size - Int2(1)) / block_size;
	dim3 block_count_dim(block_count.x, block_count.y);
	dim3 block_size_dim(block_size.x, block_size.y);

	kernel<<<block_count_dim, block_size_dim>>>(resolution, view.get_center(), view.get_extend(), surface);

	cuda_check(cudaDestroySurfaceObject(surface));
	cuda_check(cudaGraphicsUnmapResources(1, &graphics_resource));
}

void Renderer::draw(sf::RenderWindow& window)
{
	Int2 resolution(window.getSize());

	if (resolution != Int2(texture->getSize())) recreate_resources(resolution);

	launch_kernels(resolution, { 16, 16 });
	cuda_check(cudaDeviceSynchronize());

	window.draw(*sprite);
}

} // man
