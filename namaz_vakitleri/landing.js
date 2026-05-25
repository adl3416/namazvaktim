const prayerConfig = [
  { key: 'Fajr', label: 'İmsak' },
  { key: 'Sunrise', label: 'Güneş' },
  { key: 'Dhuhr', label: 'Öğle' },
  { key: 'Asr', label: 'İkindi' },
  { key: 'Maghrib', label: 'Akşam' },
  { key: 'Isha', label: 'Yatsı' },
];

const locationInput = document.querySelector('#locationInput');
const findButton = document.querySelector('#findPrayerTimes');
const geoButton = document.querySelector('#useMyLocation');
const statusBox = document.querySelector('#statusBox');
const resultsBox = document.querySelector('#resultsBox');
const resultTitle = document.querySelector('#resultTitle');
const resultMeta = document.querySelector('#resultMeta');
const nextPrayerBox = document.querySelector('#nextPrayerBox');
const prayerGrid = document.querySelector('#prayerGrid');

function showStatus(message, tone = 'info') {
  statusBox.textContent = message;
  statusBox.className = `status is-visible status--${tone}`;
}

function hideStatus() {
  statusBox.className = 'status';
  statusBox.textContent = '';
}

function normalizePrayerTime(value) {
  return (value || '').split(' ')[0].trim();
}

function formatLocationLabel(place) {
  const parts = (place.display_name || '')
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean);

  return parts.slice(0, 3).join(', ') || 'Seçilen konum';
}

function getDateString() {
  const now = new Date();
  return `${now.getDate()}-${now.getMonth() + 1}-${now.getFullYear()}`;
}

function getNowInTimeZone(timeZone) {
  return new Date(new Date().toLocaleString('en-US', { timeZone }));
}

function buildPrayerDate(baseDate, timeText) {
  const [hours, minutes] = timeText.split(':').map(Number);
  const next = new Date(baseDate);
  next.setHours(hours || 0, minutes || 0, 0, 0);
  return next;
}

function computeNextPrayer(timings, timeZone) {
  const now = getNowInTimeZone(timeZone);
  const timeline = prayerConfig.map((prayer) => {
    const timeText = normalizePrayerTime(timings[prayer.key]);
    return {
      ...prayer,
      timeText,
      date: buildPrayerDate(now, timeText),
    };
  });

  let next = timeline.find((entry) => entry.date > now);

  if (!next) {
    next = {
      ...timeline[0],
      date: new Date(timeline[0].date.getTime() + 24 * 60 * 60 * 1000),
    };
  }

  const diffMs = next.date.getTime() - now.getTime();
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
  const diffMinutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));

  return {
    ...next,
    remainingText: `${diffHours}s ${diffMinutes}dk kaldı`,
  };
}

function renderPrayerTimes(payload, locationLabel) {
  const timings = payload.data.timings;
  const timezone = payload.data.meta?.timezone || 'Europe/Istanbul';
  const gregorianDate = payload.data.date?.gregorian?.date || '';
  const nextPrayer = computeNextPrayer(timings, timezone);

  resultTitle.textContent = locationLabel;
  resultMeta.textContent = `${gregorianDate} • Saat dilimi: ${timezone} • Yöntem: Diyanet / Method 13`;
  nextPrayerBox.innerHTML = `
    <span>Sonraki vakit</span>
    <strong>${nextPrayer.label} • ${nextPrayer.timeText}</strong>
    <span>${nextPrayer.remainingText}</span>
  `;

  prayerGrid.innerHTML = prayerConfig.map((prayer) => {
    const timeText = normalizePrayerTime(timings[prayer.key]);
    const className = prayer.key === nextPrayer.key ? 'prayer-card is-next' : 'prayer-card';
    return `
      <article class="${className}">
        <span class="prayer-card__label">${prayer.label}</span>
        <div class="prayer-card__time">${timeText}</div>
      </article>
    `;
  }).join('');

  resultsBox.classList.add('is-visible');
}

async function fetchPrayerTimes(lat, lon, locationLabel) {
  const dateString = getDateString();
  const response = await fetch(
      `https://api.aladhan.com/v1/timings/${dateString}?latitude=${lat}&longitude=${lon}&method=13`,
  );

  if (!response.ok) {
    throw new Error('Namaz vakitleri servisine ulaşılamadı.');
  }

  const payload = await response.json();

  if (!payload?.data?.timings) {
    throw new Error('Namaz vakitleri alınamadı.');
  }

  renderPrayerTimes(payload, locationLabel);
}

async function searchLocation(query) {
  const response = await fetch(
      `https://nominatim.openstreetmap.org/search?format=jsonv2&limit=1&accept-language=tr&q=${encodeURIComponent(query)}`,
  );

  if (!response.ok) {
    throw new Error('Konum servisine ulaşılamadı.');
  }

  const results = await response.json();

  if (!Array.isArray(results) || results.length === 0) {
    throw new Error('Bu konum bulunamadı. İlçe, şehir ve ülke ile tekrar deneyin.');
  }

  return results[0];
}

async function reverseGeocode(lat, lon) {
  const response = await fetch(
      `https://nominatim.openstreetmap.org/reverse?format=jsonv2&accept-language=tr&lat=${lat}&lon=${lon}`,
  );

  if (!response.ok) {
    return {
      display_name: `${lat.toFixed(4)}, ${lon.toFixed(4)}`,
    };
  }

  return response.json();
}

async function handleManualLookup() {
  const query = locationInput.value.trim();

  if (!query) {
    showStatus('Lütfen ilçe, şehir veya ülke içeren bir konum girin.', 'error');
    locationInput.focus();
    return;
  }

  resultsBox.classList.remove('is-visible');
  showStatus('Konum çözümleniyor ve namaz vakitleri getiriliyor...', 'info');

  try {
    const place = await searchLocation(query);
    await fetchPrayerTimes(place.lat, place.lon, formatLocationLabel(place));
    showStatus('Namaz vakitleri güncellendi.', 'success');
  } catch (error) {
    showStatus(error.message || 'Beklenmeyen bir hata oluştu.', 'error');
  }
}

async function handleGeolocation() {
  if (!navigator.geolocation) {
    showStatus('Bu tarayıcı konum özelliğini desteklemiyor.', 'error');
    return;
  }

  resultsBox.classList.remove('is-visible');
  showStatus('Cihaz konumu alınıyor...', 'info');

  navigator.geolocation.getCurrentPosition(
      async (position) => {
        try {
          const { latitude, longitude } = position.coords;
          const place = await reverseGeocode(latitude, longitude);
          const label = formatLocationLabel(place);
          locationInput.value = label;
          await fetchPrayerTimes(latitude, longitude, label);
          showStatus('Konumdan namaz vakitleri getirildi.', 'success');
        } catch (error) {
          showStatus(error.message || 'Konumdan vakit alınamadı.', 'error');
        }
      },
      () => {
        showStatus('Konum izni verilmedi veya konum alınamadı.', 'error');
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 30000,
      },
  );
}

findButton?.addEventListener('click', handleManualLookup);
geoButton?.addEventListener('click', handleGeolocation);

locationInput?.addEventListener('keydown', (event) => {
  if (event.key === 'Enter') {
    event.preventDefault();
    handleManualLookup();
  }
});

hideStatus();
