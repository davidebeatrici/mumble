// Copyright 2005-2018 The Mumble Developers. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file at the root of the
// Mumble source tree or at <https://www.mumble.info/LICENSE>.

/*
	This plugin scans the following address locations:

		Address         Type      Description
		===================================
		0x013E8CF4      float     X-Coordinate
		0x013E8CF8      float     Y-Coordinate
		0x013E8CFC      float     Z-Coordinate
		// The XYZ coordinates repeat at 0x013F79C8, 0x013F79CC, 0x013F79D0
		// and seem to always hold the same values. It is not the camera vs
		// character, as with third person they still hold the same values.
		0x013F9E20      float     Horizontal view in degree
		0x013F9E1C      float     Vertical view in degree
		0x013E8DFC      byte      Team; 0: not in-game (in menu etc), 1: allies, 2: axis, 3: spectator
		0x009FFD30      char[40]  last connected to host IP
		0x010B4908      char[32]  map shortname only

		As reference, as help for future manual mem scanning:
		0x010B48C8      char[32]  map fullpath (relative to gamedir)
		0x03A54C9C      char[16]  last download host IP (wwwdownload)
		There seem to be a ton of memory addresses valid for the team value.

		For position coordinates:
		X-Value is increasing when heading east
		           decreasing when heading west
		Y-Value is increasing when heading north
		           decreasing when heading south
		Z-Value is increasing when going up
		           decreasing when going down
		1 unit = 1 meter (not confirmed)

		For the view angle values:
		Vertical view 0 when centered
		            -90 when looking up
		            +90 when looking down
		Increasing when looking down.

		Horizontal is 90 when facing north
		               0 when facing east
		             -90 when facing south
		          +/-180 when facing west
		Increasing when turning left.
*/

#include "../mumble_plugin_win32.h"

static int fetch(float *avatar_pos, float *avatar_front, float *avatar_top, float *camera_pos, float *camera_front, float *camera_top, MumbleString *context, MumbleWideString *) {
	float viewHor, viewVer;
	char team;

	for (int i=0;i<3;i++)
		avatar_pos[i] = avatar_front[i] = avatar_top[i] = camera_pos[i] = camera_front[i] = camera_top[i] = 0.0f;

	bool ok;
	ok = peekProc(0x013E8DFC, &team, 1);
	if (!ok)
		return false;

	// We dont use pos-audio in menus
	if (team == 0 || team == 3)
		return true;

	ok = peekProc(0x013E8CF4, avatar_pos, 12) &&   // X, Y, Z
	     peekProc(0x013F9E20, &viewHor, 4) &&      // Hor-Angle
	     peekProc(0x013F9E1C, &viewVer, 4);        // Ver-Angle

	if (!ok)
		return false;

	avatar_top[2] = -1; // Head movement is in front vector

	// Calculate view unit vector
	viewVer *= static_cast<float>(M_PI / 180.0f);
	viewHor *= static_cast<float>(M_PI / 180.0f);

	avatar_front[0] = cos(viewVer) * cos(viewHor);
	avatar_front[1] = -sin(viewVer);
	avatar_front[2] = cos(viewVer) * sin(viewHor);

	for (int i=0;i<3;i++) {
		camera_pos[i] = avatar_pos[i];
		camera_front[i] = avatar_front[i];
		camera_top[i] = avatar_top[i];
	}

	// Context - concatenated server-ip, mapname and team value
	char hostip[32];
	char mapname[40];
	ok = peekProc(0x009FFD30, hostip, sizeof(hostip)) &&
	     peekProc(0x010B4908, mapname, sizeof(hostip));
	hostip[sizeof(hostip)-1] = '\0';
	mapname[sizeof(mapname)-1] = '\0';
	// Context in JSON format, {} with fields ipport (server hostname), map, and team (: int)
	MumbleStringAssign(context, "{\"ipport\":\"" + std::string(hostip) + "\",\"map\":\"" + mapname + "\",\"team\":" + (char)(team + 0x30) + "}");

	return true;
}

static int trylock(const MumblePIDLookup lookupFunc, const MumblePIDLookupContext lookupContext) {
	if (! initialize(lookupFunc, lookupContext, L"ET.exe"))
		return false;

	float apos[3], afront[3], atop[3], cpos[3], cfront[3], ctop[3];
	MumbleString context;
	MumbleWideString identity;

	if (fetch(apos, afront, atop, cpos, cfront, ctop, &context, &identity)) {
		return true;
	} else {
		generic_unlock();
		return false;
	}
}

static MumblePlugin wolfetplug = {
	MUMBLE_PLUGIN_MAGIC,
	1,
	false,
	L"Wolfenstien: Enemy Territory",
	L"2.60b",
	L"Supports Wolfenstien: Enemy Territory. No context or identity support yet.",
	fetch,
	trylock,
	generic_unlock
};

extern "C" MUMBLE_PLUGIN_EXPORT MumblePlugin *getMumblePlugin() {
	return &wolfetplug;
}
