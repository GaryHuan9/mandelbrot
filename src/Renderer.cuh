#pragma once

#include "main.hpp"

struct cudaGraphicsResource;

namespace man
{

class Renderer
{
public:
	explicit Renderer(const View& view);

	void draw(sf::RenderWindow& window);

private:
	void recreate_resources(Int2 resolution);
	void launch_kernels(Int2 resolution, Int2 block_size);

	const View& view;

	std::unique_ptr<sf::Sprite> sprite;
	std::unique_ptr<sf::Texture> texture;

	cudaGraphicsResource* graphics_resource{};
};

} // man
