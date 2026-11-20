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

Всё остальное — оригинальный код Telegram iOS с его архитектурой, MTProto и UI.

## Сборка на GitHub

Workflow `.github/workflows/grit-build.yml`:

1. `verify-mod` — быстрая проверка, что патчи мода на месте (Ubuntu, секунды).
2. `build` — полная сборка симуляторного `.app` на раннере `xcode-27`
   (macOS 27 / Xcode 27.1, ровно под пин из `versions.json`).
3. Готовый `GRIT-TG.app` падает в артефакты workflow на 14 дней.

CI использует `build-system/grit-configuration.json` и встроенные в репозиторий
fake-codesigning сертификаты — реальный Apple-аккаунт для сборки симулятора не нужен.

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

## Важно про api_id

В `grit-configuration.json` стоит публичный тестовый `api_id` из конфигов самого
Telegram — он нужен только чтобы проект скомпилировался. Для реального использования
получите свой на <https://my.telegram.org/apps> и замените `api_id` / `api_hash`.
Не распространяйте сборку под именем Telegram и с официальным логотипом — это неофициальный клиент.

## Источники

- [TelegramMessenger/Telegram-iOS](https://github.com/TelegramMessenger/Telegram-iOS) — апстрим.
- Все изменения этого форка лежат в коммитах с префиксом `GRIT:`.
