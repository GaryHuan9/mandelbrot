#include "View.hpp"

#include <SFML/Graphics.hpp>
#include <sstream>

namespace man
{

View::View(float aspect_ratio, float zoom)
	: aspect_ratio(aspect_ratio), zoom(zoom), info_text(new sf::Text{}), info_font(new sf::Font{})
{
	update_zoom();

	info_font->loadFromFile("../ext/JetBrainsMono/JetBrainsMono-Bold.ttf");
	info_text->setFont(*info_font);
	info_text->setCharacterSize(16);
}

View::~View() = default;

void View::update_zoom()
{
	Float scale = std::exp((Float)zoom);
	extend = Float2(scale * (Float)aspect_ratio, scale);
}

void View::draw(sf::RenderWindow& window)
{
	std::chrono::time_point<Time> now = Time::now();
	Duration duration = now - last_update_time;

	if (duration.count() > SecondsToUpdate)
	{
		last_frames_per_second = (float)frames_since_update / (duration.count() * SecondsToUpdate);
		frames_since_update = 0;
		last_update_time = now;
	}

	++frames_since_update;

	std::stringstream stream;

	stream << "FPS    : " << last_frames_per_second << '\n';
	stream << "Center : " << center << '\n';
	stream << "Zoom   : " << zoom << '\n';

	info_text->setString(stream.str());
	window.draw(*info_text);
}

} // man
