#include "main.hpp"
#include "Vector2.hpp"
#include "View.hpp"
#include "Renderer.cuh"

#include <SFML/System.hpp>
#include <SFML/Window.hpp>
#include <SFML/Graphics.hpp>

int main()
{
	sf::RenderWindow window(sf::VideoMode{ 1920, 1080 }, "mandelbrot");
	sf::Clock animation_delta_clock;
	// window.setVerticalSyncEnabled(true);

	man::Float2 window_size(window.getSize());
	man::Float2 last_mouse_percent;

	man::View view(window_size.x / window_size.y);
	man::Renderer renderer(view);

	while (window.isOpen())
	{
		man::Float2 mouse_percent = man::Float2(sf::Mouse::getPosition(window)) / window_size;

		sf::Event event{};

		while (window.pollEvent(event))
		{
			switch (event.type)
			{
				case sf::Event::Closed:
				{
					window.close();
					return 0;
				}
				case sf::Event::Resized:
				{
					sf::Vector2f size(sf::Vector2u(event.size.width, event.size.height));
					window.setView(sf::View(size / 2.0f, size));
					view.set_aspect_ratio(size.x / size.y);
					window_size = man::Float2(size);
					break;
				}
				case sf::Event::MouseWheelScrolled:
				{
					view.change_zoom(event.mouseWheelScroll.delta / -16.0f, mouse_percent);
					break;
				}
				default: break;
			}
		}

		if (sf::Mouse::isButtonPressed(sf::Mouse::Button::Left))
		{
			man::Float2 point = view.get_point(last_mouse_percent);
			view.set_point(mouse_percent, point);
		}

		float zoom_delta = animation_delta_clock.restart().asSeconds();

		if (sf::Keyboard::isKeyPressed(sf::Keyboard::Key::W)) view.change_zoom(zoom_delta, mouse_percent);
		if (sf::Keyboard::isKeyPressed(sf::Keyboard::Key::S)) view.change_zoom(-zoom_delta, mouse_percent);

		last_mouse_percent = mouse_percent;
		window.clear(sf::Color::Black);

		renderer.draw(window);
		view.draw(window);
		window.display();
	}

	return 0;
}
