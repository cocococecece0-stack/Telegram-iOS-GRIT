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
| Пресеты в Настройки → Тема | обычные | добавлен **`GRIT ACID`** (день и ночь, свой градиент пузырей и грязный валлпейпер) |
| Доп. иконка | — | **`GRIT ACID`** в списке иконок (кислотный зелёный, тёмный самолёт) |

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

## Свой сертификат

Если есть свой P12 + provisioning profile — можно собрать по-настоящему подписанный билд:

1. Положите свои `.p12` в `build-system/fake-codesigning/certs/` и профили в
   `build-system/fake-codesigning/profiles/` с именами из `profile_name_mapping`
   (`Telegram.mobileprovision`, `Share.mobileprovision`, `Widget.mobileprovision`, …).
   Их `application-identifier` должен начинаться с `TEAM_ID.BUNDLE_ID`.
2. В `build-system/grit-configuration.json` поставьте свой `team_id`, `bundle_id`,
   `api_id` и `api_hash`.
3. В workflow замените `--configuration=debug_sim_arm64` на `--configuration=release_arm64`
   и добавьте сборку IPA — шаблон есть в старом `.github/workflows/build.yml` апстрима.

ТакТак вы сможете поставить свой bundle id без ошибки `aps-environment`.

## Важно про api_id

В `grit-configuration.json` стоит публичный тестовый `api_id` из конфигов самого
Telegram — он нужен только чтобы проект скомпилировался. Для реального использования
получите свой на <https://my.telegram.org/apps> и замените `api_id` / `api_hash`.
Не распространяйте сборку под именем Telegram и с официальным логотипом — это неофициальный клиент.

## Источники

- [TelegramMessenger/Telegram-iOS](https://github.com/TelegramMessenger/Telegram-iOS) — апстрим.
- Все изменения этого форка лежат в коммитах с префиксом `GRIT:`.
