# GRIT TG — грязный мод под iOS

Неофициальный форк исходников Telegram iOS. Не имеет отношения к Telegram FZ-LLC.
Сделано, чтобы было красиво, токсично и чтобы собиралось само.

## Что изменено

| Что | Было | Стало |
|---|---|---|
| Имя приложения | Telegram | **GRIT TG** |
| Bundle ID | `ph.telegra.Telegraph` | `org.grit.telegram` |
| URL-схема | `tg` | `grit` |
| Акцент в тёмной теме | `#3E88F7` | `#9EFF00` (кислотный лайм) |
| Градиент исходящих пузырей | синий/фиолетовый | `#00E676 → #9EFF00 → #1B5E20` |
| Акцент в светлой теме | `#0088FF` | `#14A33C` |
| Нейтральная ночная тема | `#3E88F7` | `#9EFF00` |
| Иконка | синий круг | зелёно-кислотный градиент (`Telegram.icon/icon.json`) |
| Кнопка на экране входа | `Start Messaging` | `ENTER THE GRIT` |
| Стартовая тема | светлая `dayClassic` | **тёмная `night` по умолчанию** |
| Пресеты в Настройки → Тема | обычные | **`GRIT ACID`** и **`GRIT VOID`** (день и ночь, свои градиенты пузырей и валлпейперы) |
| Валлпейпер чатов | стандартный пастельный градиент | **GRIT FILTH** — грязный built-in паттерн на «асфальте» |
| Вход в приложение | обычный тап | **GRIT THUMP** — короткий жёсткий haptic на `ENTER THE GRIT` |
| Доп. иконки | — | **`GRIT ACID`** (кислотный лайм) и **`GRIT VOID`** (чёрный лак + фиолетовый ток) |
| Пузыри исходящих | статический градиент | **GRIT PULSE** — плавная анимация лайм/изумруд только в GRIT-пресетах |
| Фон чата | валлпейпер | **GRIT CRT** — scanlines и зерно под сообщениями, поверх текста никогда |
| Экран входа | кнопка | **GRIT GLITCH** (дёрганый вход) + **GRIT STREAK** (`DAY N`, счётчик секретных кодов) |
| Звуки | стоковые | **GRIT SOUND** — свой искажённый удар на отправку и двухтактный звонок |
| Секрет в чате | — | набери `grit` или `enter the grit` → жёсткий haptic, поле очищается, счётчик растёт |

## GRIT-меню (появилось в v2.3)

В **Настройках** сразу после профиля идёт секция **GRIT** — без неё фишки было не найти:

- `GRIT // ACID / VOID` — переход в Настройки → Тема. Пресеты теперь доступны **для любой** базовой темы (раньше — только для Night);
- `GRIT CRT` — scanlines в чате, применяется сразу;
- `GRIT PULSE` — анимация пузырей (нужен перезапуск после смены темы);
- `GRIT SOUND` — свои звуки отправки/входящего;
- `GRIT GLITCH / THUMP` — глитч и жёсткий haptic на экране входа;
- `GRIT SECRET CODE` — триггер `grit` в поле ввода;
- `GRIT SHIELD` — приватность: маскирует экран при записи и предупреждает о скриншоте;
- `GRIT STREAK` — счётчик дней и кодов в заголовке GRIT-секции.

`GRIT FILTH` включается вместе с пресетом GRIT ACID (night). Переключатели хранятся локально в `UserDefaults`, серверные настройки Telegram не трогаются.

Всё остальное — оригинальный код Telegram iOS с его архитектурой, MTProto и UI.

\* для симуляторной сборки в `Make.py` отключены provisioning-профили: встроенные
фейк-профили апстрима просрочены (expiration 30.10.2026), поэтому без этого билд
падает на `ProcessEntitlementsFiles`. Это также позволяет использовать свой
`bundle_id` без ошибки `aps-environment`.

## Сборка на GitHub

Workflow `.github/workflows/grit-build.yml`:

1. `verify-mod` — быстрая проверка, что патчи мода на месте (Ubuntu, секунды).
2. `build` — полная сборка симуляторного `.app` на раннере `xcode-27`
   (macOS 27 / Xcode 27.1, ровно под пин из `versions.json`).
3. Готовый `GRIT-TG.app` падает в артефакты workflow на 14 дней.

CI использует `build-system/grit-configuration.json` и встроенные в репозиторий
fake-codesigning сертификаты — реальный Apple-аккаунт для сборки симулятора не нужен.

Также в `.gitmodules` URL сабмодуля `tgcalls` заменён с относительного `../tgcalls.git`
на абсолютный `https://github.com/TelegramMessenger/tgcalls.git`: иначе в форке git
пытается клонировать `cocococecece0-stack/tgcalls`, которого не существует.

Локально (нужны macOS + Xcode из `versions.json`):

```bash
git clone --recursive -j8 https://github.com/cocococecece0-stack/Telegram-iOS-GRIT.git
cd Telegram-iOS-GRIT
python3 build-system/Make/ImportCertificates.py --path build-system/fake-codesigning/certs
python3 -u build-system/Make/Make.py \
  --overrideXcodeVersion \
  build \
  --configurationPath=build-system/grit-configuration.json \
  --codesigningInformationPath=build-system/fake-codesigning \
  --configuration=debug_sim_arm64 \
  --buildNumber=1
```

## Свой сертификат — подписанный IPA

Да, подписать можно. Для этого есть отдельный workflow
`.github/workflows/signed-build.yml` (Actions → **GRIT signed IPA → Run workflow**).

Залейте в GitHub Secrets (Settings → Secrets and variables → Actions):

| Secret | Что |
|---|---|
| `GRIT_P12_BASE64` | ваш `.p12`, `base64 -i cert.p12 -o -` |
| `GRIT_P12_PASSWORD` | пароль от p12 |
| `GRIT_PROFILE_BASE64` | provisioning profile основного приложения, base64 |
| `GRIT_TEAM_ID` | ваш Apple Team ID |
| `GRIT_API_ID` / `GRIT_API_HASH` | свои креды Telegram API |
| `GRIT_KEYCHAIN_PASSWORD` | *(опционально)* пароль временного keychain |

Bundle id задаётся переменной `GRIT_BUNDLE_ID` (по умолчанию `org.grit.telegram`).
Профиль должен иметь `application-identifier` вида `TEAM_ID.<bundle_id>` и содержать
`aps-environment`, иначе Make.py остановится с понятным сообщением.

Workflow импортирует сертификат во временный keychain, собирает `release_arm64` и
кладет подписанный `GRIT-TG-signed.ipa` в артефакты. Расширения (Share/Widget/…) в
этой сборке отключены через `GRIT_DISABLE_EXTENSIONS=1`: достаточно одного профиля
на основное приложение. Это **не сайдлоад**: IPA уже подписан твоим сертификатом и
устанавливается через Xcode Devices, Apple Configurator, MDM или напрямую как обычный
ад-hoc/distribution билд.

Если сертификат нужно наложить самому (свой Mac или другой сервис подписи), есть отдельный
workflow `.github/workflows/device-ipa.yml` (Actions → **GRIT device IPA** → Run workflow).
Он собирает `release_arm64` без просроченных встроенных provisioning-профилей
(`GRIT_DISABLE_PROVISIONING=1`) и выдает `GRIT-TG-device-unsigned.ipa`, который можно
переподписать своим P12 локально. Симуляторный `.app` из `grit-build.yml` на реальный
айфон не ставится — для устройства нужен именно device IPA из одного из этих двух workflow.

## Важно про api_id

В `grit-configuration.json` стоит публичный тестовый `api_id` из конфигов самого
Telegram — он нужен только чтобы проект скомпилировался. Для реального использования
получите свой на <https://my.telegram.org/apps> и замените `api_id` / `api_hash`.
Не распространяйте сборку под именем Telegram и с официальным логотипом — это неофициальный клиент.

## Источники

- [TelegramMessenger/Telegram-iOS](https://github.com/TelegramMessenger/Telegram-iOS) — апстрим.
- Все изменения этого форка лежат в коммитах с префиксом `GRIT:`.
