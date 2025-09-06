if (GAME_LOCALE or GetLocale()) ~= "ruRU" then return end

local AddonName, Addon = ...

local L = {}

Addon.L = L

L.GlowTypeTitle = "Свечения прока"
L.GlowTypeDesc = "Можно выбрать тип и цвет цикличного свечения прока"
L.GlowType = "Тип цикличного свечения"

L.UseCustomColor = "Использовать свой цвет"

L.Desaturate = "Обесцветить"

L.ProcStartTitle = "Стартовое свечение прока"
L.ProcTypeDesc = "Можно отключить или изменить тип и цвет стартовой анимации прока"
L.HideProcAnim = "Скрыть начальную анимацию прока"
L.StartProcType = "Тип начальной анимации прока"

L.FadeTitle = "Скрытие панелей"
L.FadeDesc = "Можно включить скрытие панелей и когда они будут появляться"
L.FadeOutBars = "Использовать прозрачность панелей"
L.FadeInOnCombat = "Показывать в бою"
L.FadeInOnTarget = "Показывать при наличии цели"
L.FadeInOnCasting = "Показывать во время каста"
L.FadeInOnHover = "Показывать при наведении мыши"

L.PushedTitle = "Стиль текстуры нажатой кнопки"
L.PushedDesc = "Эта текстура отображается в момент нажатия кнопки"
L.PushedTextureType = "Текстура нажатой кнопки"

L.HighlightTitle = "Стиль текстуры подсветки"
L.HighlightDesc = "Эта текстура отображается в момент наведения курсора на кнопку"
L.HighliteTextureType = "Текстура при наведении мыши"

L.CheckedTitle = "Стиль текстуры активной кнопки"
L.CheckedDesc = "Эта текстура отображается когда заклинание успешно применено или находится в очереди заклинаний"
L.CheckedTextureType = "Текстура активной кнопки"

L.ColorOverrideTitle = "Цвет статуса кнопки"
L.ColorOverrideDesc = "Можно выбрать цвет для некоторых статусов кнопки"
L.CustomColorCooldownSwipe = "Использовать свой цвет для кудлауна"
L.CustomColorOOR = "Свой цвет Out Of Range"
L.CustomColorOOM = "Свой цвет Out Of Mana"
L.CustomColorNoUse = "Свой цвет если кнопка недоступна"

L.HideFrameTitle = "Скрытие панелей и анимаций"
L.HideFrameDesc = "Можно отключить отображение некоторых панелей и раздражающих анимаций на панели способностей"
L.HideBagsBar = "Скрывать панель сумок"
L.HideMicroMenuBar = "Скрывать микроменю"
L.HideInterrupt = "Скрывать анимацию прерывания на кнопке"
L.HideCasting = "Скрывать анимацию каста на кнопке"
L.HideReticle = "Скрывать анимацию АОЕ на кнопке"

L.FontTitle = "Настройки шрифта"
L.FontDesc = "Можно изменить масштаб текста кнопок. Повлияет только на кнопки с машстабом <100%"
L.FontHotKeyScale = "Масштаб шрифта Хоткеев"
L.FontStacksScale = "Масштаб шрифта Стаков"
L.FontNameScale = "Масштаб шрифта Названия"