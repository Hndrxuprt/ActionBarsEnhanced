if (GAME_LOCALE or GetLocale()) ~= "ruRU" then return end

local AddonName, Addon = ...

local L = {}

Addon.L = L

L.GlowTypeTitle = "Свечение прока"
L.GlowTypeDesc = "Выбрать тип и цвет цикличного свечения прока"
L.GlowType = "Тип цикличного свечения"

L.UseCustomColor = "Использовать свой цвет"

L.Desaturate = "Обесцветить"

L.ProcStartTitle = "Стартовое свечение прока"
L.ProcStartDesc = "Отключить или изменить тип и цвет стартовой анимации прока"
L.HideProcAnim = "Скрыть начальную анимацию прока"
L.StartProcType = "Тип начальной анимации прока"

L.AssistTitle = "Свечение Боевого Помощника"
L.AssistDesc = "Выбрать тип и цвет основного и дополнительного свечения"
L.AssistType = "Тип основного свечения"
L.AssistAltType = "Тип второстепенного свечения"

L.FadeTitle = "Скрытие панелей"
L.FadeDesc = "Активировать скрытие панелей и настроить условия отображения.\n|cffff2020/reload для включения/отключения|r"
L.FadeOutBars = "Использовать прозрачность панелей"
L.FadeInOnCombat = "Показывать в бою"
L.FadeInOnTarget = "Показывать при наличии цели"
L.FadeInOnCasting = "Показывать во время каста"
L.FadeInOnHover = "Показывать при наведении мыши"

L.PushedTitle = "Стиль текстуры нажатой кнопки"
L.PushedDesc = "Эта текстура отображается в момент нажатия кнопки.\n|cffff2020требуется /reload|r"
L.PushedTextureType = "Текстура нажатой кнопки"

L.HighlightTitle = "Стиль текстуры подсветки"
L.HighlightDesc = "Эта текстура отображается в момент наведения курсора на кнопку.\n|cffff2020требуется /reload|r"
L.HighliteTextureType = "Текстура при наведении мыши"

L.CheckedTitle = "Стиль текстуры активной кнопки"
L.CheckedDesc = "Текстура примененного заклинания или если оно находится в очереди заклинаний.\n|cffff2020требуется /reload|r"
L.CheckedTextureType = "Текстура активной кнопки"

L.ColorOverrideTitle = "Цвет статуса кнопки"
L.ColorOverrideDesc = "Выбрать цвет для некоторых статусов кнопки.\n|cffff2020требуется /reload|r"
L.CustomColorCooldownSwipe = "Использовать свой цвет для кудлауна"
L.CustomColorOOR = "Свой цвет Out Of Range"
L.CustomColorOOM = "Свой цвет Out Of Mana"
L.CustomColorNoUse = "Свой цвет если кнопка недоступна"

L.HideFrameTitle = "Скрытие панелей и анимаций"
L.HideFrameDesc = "Отключить отображение панелей и раздражающих анимаций на панели способностей.\n|cffff2020требуется /reload|r"
L.HideBagsBar = "Скрывать панель сумок"
L.HideMicroMenuBar = "Скрывать микроменю"
L.HideInterrupt = "Скрывать анимацию прерывания на кнопке"
L.HideCasting = "Скрывать анимацию каста на кнопке"
L.HideReticle = "Скрывать анимацию АОЕ на кнопке"

L.FontTitle = "Настройки шрифта"
L.FontDesc = "Изменить масштаб текста кнопок. Влияет только на кнопки с машстабом <100%\n|cffff2020требуется /reload|r"
L.FontHotKeyScale = "Масштаб шрифта Хоткеев"
L.FontStacksScale = "Масштаб шрифта Стаков"
L.FontNameScale = "Масштаб шрифта Названия"

L.welcomeMessage1 = "Спасибо за использование |cff1df2a8ActionBars Enhanced|r"
L.welcomeMessage2 = "Вы можете открыть настройки командой |cff1df2a8/"