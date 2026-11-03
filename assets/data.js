/* Static game definitions. UI text is Russian; identifiers remain English. */
window.STData = (() => {
  'use strict';
  const presets = {
    science:{label:'Исследователь',role:'Наука и дальняя связь',color:'#84b9e5',base:{cargo:28,science:62,combat:16,speed:40,durability:52},cost:{credits:2400,alloy:70,fuel:18},buildTime:45,crew:3,unlock:null,params:{length:26,width:6,height:4,span:29,sweep:25,segments:5,wingType:'solar',nozzles:4,plasma:'#6aabff',glow:1.4,greebles:55,turrets:2,antennas:true,scanners:true,hullColor:'#d8e0e0',accentColor:'#e7a454',metalness:.65,roughness:.4}},
    cargo:{label:'Грузовоз',role:'Тяжёлые перевозки',color:'#efb575',base:{cargo:78,science:12,combat:12,speed:24,durability:70},cost:{credits:2200,alloy:90,fuel:24},buildTime:50,crew:4,unlock:null,params:{length:32,width:7,height:5,span:19,sweep:15,segments:6,wingType:'delta',nozzles:6,plasma:'#ffab62',glow:1.2,greebles:75,turrets:2,antennas:true,scanners:true,hullColor:'#b89a50',accentColor:'#e6b84e',metalness:.55,roughness:65/100}},
    interceptor:{label:'Перехватчик',role:'Скорость и сопровождение',color:'#99eed5',base:{cargo:14,science:18,combat:52,speed:82,durability:44},cost:{credits:1900,alloy:55,fuel:20},buildTime:35,crew:2,unlock:null,params:{length:28,width:5,height:3,span:24,sweep:30,segments:5,wingType:'forward',nozzles:2,plasma:'#79f5ed',glow:1.9,greebles:35,turrets:2,antennas:true,scanners:true,hullColor:'#c5d1da',accentColor:'#ef8b55',metalness:.7,roughness:.35}},
    military:{label:'Дредноут',role:'Силовое превосходство',color:'#ff7b88',base:{cargo:24,science:14,combat:92,speed:28,durability:88},cost:{credits:4300,alloy:150,fuel:40},buildTime:90,crew:6,unlock:'military_doctrine',params:{length:34,width:9,height:5,span:29,sweep:32,segments:7,wingType:'multi',nozzles:6,plasma:'#ffab62',glow:1.5,greebles:85,turrets:8,antennas:true,scanners:true,hullColor:'#536170',accentColor:'#d6754d',metalness:.45,roughness:.7}},
    alien:{label:'Био-корабль',role:'Экзотические исследования',color:'#bf8aff',base:{cargo:18,science:80,combat:28,speed:58,durability:40},cost:{credits:4800,alloy:120,fuel:28},buildTime:100,crew:3,unlock:'xenobiology',params:{length:27,width:7,height:5,span:28,sweep:38,segments:6,wingType:'swept',nozzles:3,plasma:'#bf8aff',glow:2,greebles:30,turrets:2,antennas:false,scanners:true,hullColor:'#315b60',accentColor:'#c176df',metalness:.35,roughness:.3}},
    raider:{label:'Рейдер',role:'Нестандартные операции',color:'#ec6fa8',base:{cargo:18,science:16,combat:66,speed:70,durability:48},cost:{credits:3100,alloy:95,fuel:26},buildTime:60,crew:3,unlock:'irregular_tactics',params:{length:27,width:7,height:4,span:26,sweep:42,segments:5,wingType:'forward',nozzles:4,plasma:'#bf8aff',glow:2.1,greebles:80,turrets:6,antennas:true,scanners:true,hullColor:'#4b505f',accentColor:'#ec5b98',metalness:.8,roughness:.5}}
  };
  const stats={cargo:'Груз',science:'Наука',combat:'Бой',speed:'Скорость',durability:'Прочность'};
  const sectors={
    earth:{name:'Орбита Земли',short:'Земля',x:24,y:60,distance:1,tier:1,color:'#99eed5',desc:'Домашний кластер: доки, станции снабжения и научные платформы.',unlock:{}},
    moon:{name:'Лунная верфь',short:'Луна',x:42,y:37,distance:1.4,tier:2,color:'#c9d5e5',desc:'Промышленный узел и главный рынок тяжёлых грузов.',unlock:{yard:1,reputation:8}},
    mars:{name:'Марсианский коридор',short:'Марс',x:60,y:62,distance:2.1,tier:3,color:'#ef9b75',desc:'Дальние колонии нуждаются в сопровождении и снабжении.',unlock:{yard:2,tech:'navigation'}},
    belt:{name:'Пояс астероидов',short:'Пояс',x:72,y:30,distance:2.8,tier:4,color:'#efb575',desc:'Добыча, спасательные операции и независимые контрактёры.',unlock:{yard:3,reputation:35}},
    jupiter:{name:'Юпитерианская система',short:'Юпитер',x:84,y:66,distance:3.8,tier:5,color:'#d6b28d',desc:'Газовые гиганты, орбитальные лаборатории и ценные данные.',unlock:{yard:4,tech:'deep_space'}},
    deep:{name:'Дальний рубеж',short:'Рубеж',x:92,y:18,distance:5,tier:5,color:'#bf8aff',desc:'Экспедиции за пределы освоенного пространства.',unlock:{yard:5,tech:'slipstream',reputation:90}}
  };
  const factions={
    terran:{name:'Терранский альянс',color:'#99eed5',desc:'Государственные перевозки и орбитальная безопасность.',perk:'Награда за контракты +{n}%'},
    lunar:{name:'Лунный консорциум',color:'#efb575',desc:'Промышленность, добыча и тяжёлая логистика.',perk:'Закупка сплава дешевле на {n}%'},
    helios:{name:'Гелиос Корп',color:'#84b9e5',desc:'Исследования, энергетика и дальней связи.',perk:'Производство исследований +{n}%'},
    frontier:{name:'Коалиция Рубежа',color:'#bf8aff',desc:'Разведка, независимые колонии и спасение.',perk:'Длительность миссий −{n}%'}
  };
  const contractTypes={
    cargo:{label:'Грузоперевозка',stat:'cargo',icon:'alloy',faction:'lunar',titles:['Доставка строительных модулей','Контейнерный экспресс','Снабжение колонии','Перевозка топлива']},
    science:{label:'Научная миссия',stat:'science',icon:'research',faction:'helios',titles:['Спектральный анализ','Запуск зондов','Орбитальная лаборатория','Карта магнитосферы']},
    combat:{label:'Сопровождение',stat:'combat',icon:'shield',faction:'terran',titles:['Сопровождение конвоя','Патруль коридора','Защита дока','Перехват контрабандистов']},
    survey:{label:'Разведка',stat:'science',icon:'radar',faction:'frontier',titles:['Разведка маршрута','Поиск спутника','Дальняя телеметрия','Сканирование обломков']},
    rescue:{label:'Спасательная операция',stat:'durability',icon:'wrench',faction:'frontier',titles:['Эвакуация экипажа','Буксировка судна','Подъём контейнера','Аварийный ремонт']}
  };
  const modules={
    yard:{name:'Верфь',icon:'shipyard',desc:'Уровень контрактов и скорость постройки.',energy:4,base:{credits:1300,alloy:55},effect:l=>`Контракты T${l} · постройка +${l*8}%`},
    hangar:{name:'Ангар',icon:'hangar',desc:'Вместимость флота.',energy:2,base:{credits:800,alloy:35},effect:l=>`${2+l*2} кораблей`},
    drydock:{name:'Сухой док',icon:'wrench',desc:'Скидка на ремонт и строительство.',energy:3,base:{credits:650,alloy:24},effect:l=>`Скидка ${l*4}% · ремонт +${l*10}%`},
    control:{name:'Центр управления',icon:'radar',desc:'Шанс успеха миссий.',energy:3,base:{credits:750,alloy:10,research:14},effect:l=>`Шанс +${l*4}%`},
    refinery:{name:'Переработчик',icon:'alloy',desc:'Производство сплава.',energy:4,base:{credits:600,alloy:18},effect:l=>`+${l*3} сплава / цикл`},
    lab:{name:'Лаборатория',icon:'research',desc:'Производство исследований.',energy:4,base:{credits:700,alloy:12,research:10},effect:l=>`+${l*2} исслед. / цикл`},
    trade:{name:'Торговый узел',icon:'credit',desc:'Регулярный доход станции.',energy:2,base:{credits:800,alloy:12},effect:l=>`+${l*35} ₡ / цикл`},
    solar:{name:'Солнечные панели',icon:'sun',desc:'Энергоснабжение всех модулей.',energy:0,base:{credits:550,alloy:28},effect:l=>`+${l*18} энергии`},
    habitat:{name:'Жилой модуль',icon:'crew',desc:'Вместимость экипажа и отдых.',energy:3,base:{credits:650,alloy:22},effect:l=>`${6+l*4} мест экипажа`},
    fuel:{name:'Топливный синтезатор',icon:'fuel',desc:'Производство топлива.',energy:5,base:{credits:720,alloy:26},effect:l=>`+${l*3} топлива / цикл`},
    relay:{name:'Навигационный релей',icon:'orbit',desc:'Сокращение длительности полётов.',energy:3,base:{credits:900,alloy:20,research:18},effect:l=>`Время миссий −${l*4}%`}
  };
  const techBranches={engineering:'Инженерия',logistics:'Логистика',science:'Наука',economy:'Экономика'};
  const techs={
    alloys:{name:'Новые сплавы',branch:'engineering',tier:1,requires:[],cost:{credits:500,research:20},time:40,desc:'Прочность кораблей +8%.',effect:{durability:.08}},
    construction:{name:'Модульная сборка',branch:'engineering',tier:1,requires:[],cost:{credits:650,research:25},time:45,desc:'Постройка кораблей на 15% быстрее.',effect:{buildSpeed:.15}},
    military_doctrine:{name:'Военная доктрина',branch:'engineering',tier:2,requires:['alloys'],cost:{credits:1200,research:55},time:75,desc:'Открывает дредноуты. Бой +6%.',effect:{combat:.06}},
    navigation:{name:'Дальняя навигация',branch:'logistics',tier:1,requires:[],cost:{credits:600,research:24},time:45,desc:'Открывает Марс. Скорость +6%.',effect:{speed:.06}},
    logistics:{name:'Умная логистика',branch:'logistics',tier:2,requires:['navigation'],cost:{credits:900,research:45},time:60,desc:'Груз +12%, расход топлива −10%.',effect:{cargo:.12,fuelUse:-.1}},
    deep_space:{name:'Дальний космос',branch:'logistics',tier:3,requires:['logistics'],cost:{credits:1600,research:85},time:95,desc:'Открывает Юпитер. Время миссий −8%.',effect:{missionTime:-.08}},
    sensors:{name:'Сенсорные сети',branch:'science',tier:1,requires:[],cost:{credits:550,research:22},time:40,desc:'Наука +10%.',effect:{science:.1}},
    xenobiology:{name:'Ксенобиология',branch:'science',tier:2,requires:['sensors'],cost:{credits:1300,research:65},time:80,desc:'Открывает био-корабли.',effect:{}},
    slipstream:{name:'Слипстрим-двигатель',branch:'science',tier:3,requires:['xenobiology','deep_space'],cost:{credits:2400,research:130},time:120,desc:'Открывает Дальний рубеж. Скорость +15%.',effect:{speed:.15}},
    markets:{name:'Рыночная аналитика',branch:'economy',tier:1,requires:[],cost:{credits:500,research:18},time:35,desc:'Доход станции +10%.',effect:{income:.1}},
    automation:{name:'Автоматизация',branch:'economy',tier:2,requires:['markets','construction'],cost:{credits:1000,research:50},time:70,desc:'Производство станции +20%.',effect:{production:.2}},
    irregular_tactics:{name:'Нестандартные операции',branch:'economy',tier:2,requires:['markets'],cost:{credits:1100,research:48},time:65,desc:'Открывает рейдеры. Награда +5%.',effect:{reward:.05}}
  };
  const roles={captain:{name:'Капитан',stat:'speed',desc:'Шанс миссии и скорость'},engineer:{name:'Инженер',stat:'durability',desc:'Прочность и износ'},pilot:{name:'Пилот',stat:'combat',desc:'Скорость и бой'},scientist:{name:'Учёный',stat:'science',desc:'Наука и исследования'}};
  const crewNames=['Алексей Волков','Мира Чен','Идрис Коул','София Орлова','Лев Арден','Ная Сингх','Марк Рейес','Юна Ким','Элис Нова','Тимур Белов','Кира Старк','Дан Алер','Лея Морган','Орэн Вейл','Ася Луч','Роман Кейн'];
  const achievements={
    first_contract:{name:'Первый рейс',desc:'Завершить первый контракт',goal:1,metric:'missions',reward:{credits:500}},
    fleet_3:{name:'Малый флот',desc:'Иметь 3 корабля',goal:3,metric:'ships',reward:{alloy:50}},
    builder:{name:'Авторский проект',desc:'Построить корабль в 3D-конструкторе',goal:1,metric:'custom',reward:{research:25}},
    rich:{name:'Устойчивый бизнес',desc:'Заработать 20 000 ₡ на контрактах',goal:20000,metric:'earned',reward:{credits:2000}},
    researcher:{name:'Научный прорыв',desc:'Изучить 4 технологии',goal:4,metric:'techs',reward:{research:60}},
    station_5:{name:'Орбитальный узел',goal:8,metric:'modules',desc:'Суммарно 8 уровней модулей',reward:{alloy:100}},
    explorer:{name:'За пределами орбиты',desc:'Открыть 3 сектора',goal:3,metric:'sectors',reward:{credits:1500}},
    veteran:{name:'Надёжная репутация',desc:'Достичь 50 репутации',goal:50,metric:'reputation',reward:{credits:2500,research:40}}
  };
  const events={
    solar_flare:{name:'Солнечная вспышка',desc:'Энергосистема перегружена: производство станции −25%.',duration:90,effect:{production:-.25},kind:'bad'},
    market_boom:{name:'Промышленный бум',desc:'Спрос на сплав вырос: цена продажи +25%.',duration:120,effect:{alloyPrice:.25},kind:'good'},
    rescue_call:{name:'Сигнал бедствия',desc:'Срочный контракт спасения добавлен на доску.',duration:1,effect:{contract:'rescue'},kind:'info'},
    grant:{name:'Грант Альянса',desc:'Репутация станции привлекла финансирование.',duration:1,effect:{credits:600},kind:'good'},
    quiet_shift:{name:'Спокойная смена',desc:'Диспетчеры работают слаженно: шанс миссий +5%.',duration:100,effect:{chance:.05},kind:'good'}
  };
  return {presets,stats,sectors,factions,contractTypes,modules,techBranches,techs,roles,crewNames,achievements,events};
})();
