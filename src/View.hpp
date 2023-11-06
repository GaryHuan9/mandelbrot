#pragma once

#include "main.hpp"
#include "Vector2.hpp"
#include <algorithm>
#include <chrono>

typedef std::chrono::steady_clock Time;
typedef std::chrono::duration<float> Duration;

namespace man
{

class View
{
public:
	explicit View(float aspect_ratio, float zoom = 0.0f);
	~View();

	void set_aspect_ratio(float value)
	{
		if (value == aspect_ratio) return;
		aspect_ratio = value;
		update_zoom();
	}

	[[nodiscard]]
	Float2 get_center() const { return center; }

	[[nodiscard]]
	Float2 get_extend() const { return extend; }

	[[nodiscard]]
	Float2 get_point(Float2 percent) const
	{
		percent = percent * (Float)2.0 - Float2((Float)1.0);
		return center + extend * percent;
	}

	void set_point(Float2 percent, Float2 point)
	{
		percent = percent * (Float)2.0 - Float2((Float)1.0);
		center = point - extend * percent;
	}

	float change_zoom(float delta)
	{
		float new_zoom = std::clamp(zoom + delta, -30.0f, 1.0f);
		if (new_zoom == zoom) return zoom;

		zoom = new_zoom;
		update_zoom();
		return zoom;
	}

	float change_zoom(float delta, Float2 percent)
	{
		Float2 point = get_point(percent);
		float result = change_zoom(delta);
		set_point(percent, point);
		return result;
	}

	void draw(sf::RenderWindow& window);

private:
	void update_zoom();

	Float2 center;
	Float2 extend;
	float aspect_ratio;
	float zoom;

	constexpr static float SecondsToUpdate = 0.5f;
	std::chrono::time_point<Time> last_update_time;
	uint32_t frames_since_update{};
	float last_frames_per_second{};

	const std::unique_ptr<sf::Font> info_font;
	const std::unique_ptr<sf::Text> info_text;
};

} // man
