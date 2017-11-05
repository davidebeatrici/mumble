// Copyright 2005-2018 The Mumble Developers. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file at the root of the
// Mumble source tree or at <https://www.mumble.info/LICENSE>.

#include "../mumble_plugin.h"

#include <stdio.h>
#include <stdint.h>
#include <wchar.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/mman.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>

static wchar_t pluginname[256] = L"Link";
static wchar_t description[2048] = L"Reads audio position information from linked game";

static char memname[256];

struct LinkedMem {
	uint32_t uiVersion;
	uint32_t ui32count;
	float	fAvatarPosition[3];
	float	fAvatarFront[3];
	float	fAvatarTop[3];
	wchar_t	name[256];
	float	fCameraPosition[3];
	float	fCameraFront[3];
	float	fCameraTop[3];
	wchar_t	identity[256];
	uint32_t context_len;
	unsigned char context[256];
	wchar_t description[2048];
};

/// Non-monotonic tick count in ms resolution
static int64_t GetTickCount() {
	struct timeval tv;
	gettimeofday(&tv,NULL);

	return tv.tv_usec / 1000 + tv.tv_sec * 1000;
}

#define lm_invalid reinterpret_cast<struct LinkedMem *>(-1)
static struct LinkedMem *lm = lm_invalid;
static int shmfd = -1;

static int64_t last_tick = 0;
static uint32_t last_count = 0;

static void unlock() {
	lm->ui32count = last_count = 0;
	lm->uiVersion = 0;
	lm->name[0] = 0;
	wcscpy(pluginname, L"Link");
	wcscpy(description, L"Reads audio position information from linked game");
}

static int trylock(const MumblePIDLookup, const MumblePIDLookupContext) {
	if (lm == lm_invalid)
		return false;

	if ((lm->uiVersion == 1) || (lm->uiVersion == 2)) {
		if (lm->ui32count != last_count) {
			last_tick = GetTickCount();
			last_count = lm->ui32count;

			if (lm->name[0]) {
				wcsncpy(pluginname, lm->name, 256);
				pluginname[255] = 0;
			}
			if (lm->description[0]) {
				wcsncpy(description, lm->description, 2048);
				description[2047] = 0;
			}
			return true;
		}
	}
	return false;
}

static int fetch(float *avatar_pos, float *avatar_front, float *avatar_top,
                 float *camera_pos, float *camera_front, float *camera_top,
                 MumbleString *context, MumbleWideString *identity) {

	if (lm->ui32count != last_count) {
		last_tick = GetTickCount();
		last_count = lm->ui32count;
	} else if ((GetTickCount() - last_tick) > 5000)
		return false;

	if ((lm->uiVersion != 1) && (lm->uiVersion != 2))
		return false;

	for (int i=0;i<3;++i) {
		avatar_pos[i]=lm->fAvatarPosition[i];
		avatar_front[i]=lm->fAvatarFront[i];
		avatar_top[i]=lm->fAvatarTop[i];
	}

	if (lm->uiVersion == 2) {
		for (int i=0;i<3;++i) {
			camera_pos[i]=lm->fCameraPosition[i];
			camera_front[i]=lm->fCameraFront[i];
			camera_top[i]=lm->fCameraTop[i];
		}

		MumbleStringAssign(context, std::string(reinterpret_cast<const char*>(lm->context), std::min(255u, lm->context_len)));
		lm->identity[255] = 0;
		MumbleStringAssign(identity, lm->identity);
	} else {
		for (int i=0;i<3;++i) {
			camera_pos[i]=lm->fAvatarPosition[i];
			camera_front[i]=lm->fAvatarFront[i];
			camera_top[i]=lm->fAvatarTop[i];
		}
		MumbleStringClear(context);
		MumbleStringClear(identity);
	}

	return true;
}

__attribute__((constructor))
static void load_plugin() {
	bool bCreated = false;

	snprintf(memname, 256, "/MumbleLink.%d", getuid());

	shmfd = shm_open(memname, O_RDWR, S_IRUSR | S_IWUSR);
	if (shmfd < 0) {
		bCreated = true;
		shmfd = shm_open(memname, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR);
	}

	if (shmfd < 0) {
		fprintf(stderr,"Mumble Link plugin: error creating shared memory\n");
		return;
	}

	if (bCreated) {
		if (ftruncate(shmfd, sizeof(struct LinkedMem)) != 0) {
			fprintf(stderr, "Mumble Link plugin: failed to resize shared memory\n");
			close(shmfd);
			shmfd = -1;
			return;
		}
	}

	lm = static_cast<struct LinkedMem*>(
	         mmap(NULL, sizeof(struct LinkedMem), PROT_READ | PROT_WRITE, MAP_SHARED, shmfd,0));

	if ((lm != lm_invalid) && bCreated)
		memset(lm, 0, sizeof(struct LinkedMem));
}

__attribute__((destructor))
static void unload_plugin() {
	if (lm != lm_invalid)
		munmap(lm, sizeof(struct LinkedMem));

	if (shmfd > -1)
		close(shmfd);

	shm_unlink(memname);
}

static MumblePlugin linkplug = {
	MUMBLE_PLUGIN_MAGIC,
	120,
	false,
	pluginname,
	L"Universal",
	description,
	fetch,
	trylock,
	unlock,
};

extern "C" MUMBLE_PLUGIN_EXPORT MumblePlugin *getMumblePlugin() {
	return &linkplug;
}
