# POA Roaming

Блокчейн роаминг для управления зарядными станциями. 

Схема взаимодействия: https://miro.com/app/board/uXjVP68PVCs=/

## Структуры данных 

### Станции
Структура данных `Station`:

```
string ClientUrl; // уникальный идентификатор по которому подключается ocpp.
address Owner; // адрес владельца станции (т.е. адрес сети)
string Name; // название станции
string LocationLat; // координаты
string LocationLon; // координаты
string Address; // адрес местонахождения
string Time; // время работы станции
string ChargePointModel; 
string ChargePointVendor;
string ChargeBoxSerialNumber;
string FirmwareVersion;
bool IsActive; // показывать станцию пользователям или нет
bool State; // состояние станции (онлайн или офлайн)
string Url; // сайт владельца станции
int Type; // тип станции (dc, ac)
uint256 OcppInterval; // интервал запроса ocpp heartbeat
uint256 Heartbeat; // временная метка последнего heardbeat
Connectors[] Connectors; // список коннекторов 
```




### Коннекторы

Структура данных `Connector`:

```
uint256 Price; // цена        
int ConnectorId; // номер коннектора
int connectorType; // тип коннектора (см. константы)
int PriceFor; // цена за квт или минуты (см. константы)
int Status; // статус коннектора (см. константы)
int ErrorCode; // номер ошибки
bool IsHaveLock; // есть ли замок у коннектора
```


Константы для типов коннекторов `connectorType`

```
int constant Type1 = 1;
int constant Type2 = 2;
int constant Chademo = 3;
int constant CCS1 = 4;
int constant CCS2 = 5;
int constant GBTDC = 6;
int constant GBTAC = 7;
```

Константы для статусов коннекторов `Connector.Status`

```
int constant Available =  1;
int constant Preparing = 2;
int constant Charging = 3;
int constant SuspendedEVSE = 4;
int constant SuspendedEV = 5;
int constant Finishing = 6;
int constant Reserved = 7;
int constant Unavailable = 8;
int constant Faulted = 9;
```

Константы для кодов ошибок `Connector.ErrorCode`

```
int constant ConnectorLockFailure = 1;
int constant EVCommunicationError = 2;
int constant GroundFailure = 3;
int constant HighTemperature = 4;
int constant InternalError = 5;
int constant LocalListConflict = 6;
int constant NoError = 7;
int constant OtherError = 8;
int constant OverCurrentFailure = 9;
int constant PowerMeterFailure = 10;
int constant PowerSwitchFailure = 11;
int constant ReaderFailure = 12;
int constant ResetFailure = 13;
int constant UnderVoltage = 14;
int constant OverVoltage = 15;
int constant WeakSignalint = 16;
```

Константы для типоов расчета `Connector.PriceFor`

```
int constant Kw = 1;
int constant Time = 2;
```


### Транзакции


Структура данных `Transaction`:

```
address initiator; // кто начал транзакцию 
uint256 totalPrice; // итоговая сумма к оплате
uint256 totalImportRegisterWh; // итоговое кол-во потребленных ватт
bool isPaidToOwner; // оплачена транзакция владельцу или нет, менять состояние может только владелец
uint256 idtag; // метка клиента который запустил транзакцию
uint256 MeterStart; // ватты в начале транзакции
uint256 LastMeter; // последние полученные ватты из MeterValues, по этому значению можно посчитать на сколько зарядился человек в данный момент времени
uint256 MeterStop; // ватты в конце транзакции
uint256 DateStart; // метка времени начала транзакции
uint256 DateStop; // метка времени окончания транзакции
uint256 ConnectorPrice; // цена
uint256 StationId; // id станции
int ConnectorId; // id коннектора
int State; // состояние (см. константы)
int ConnectorPriceFor; // цена за квт или минуты (см. константы)
```

Структура данных `MeterValue`:

```
uint256 TransactionId;
int ConnectorId;
uint256 EnergyActiveImportRegister_Wh; // Сколько ватт машина получила на текущий момент
int CurrentImport_A; // Текущий ампераж
int CurrentOffered_A; // Максимальный ток который предложила станция
int PowerActiveImport_W; // Текущая мощность в ваттах
int Voltage_V; // Текущее напряжение
```


Константы для типоов расчета `Transaction.ConnectorPriceFor`

```
int constant Kw = 1;
int constant Time = 2;
```

Константы для состояния транзакции `Transaction.State`


```
int constant New = 1; 
int constant Preparing = 2;
int constant Charging = 3;
int constant Finished = 4;
int constant Error = 5;
```

## Методы

### Станции

> addStation(StationStruct) 

Добавить станцию, получает на входе стуктуру `Station`

> getStations() 

Возвращает список всех станций в сети роаминга, массив в формате [ id => clientUrl ]

> getStationByUrl(clienturl) returns(StationStruct)

Получить полную актуальную информацию о станции по clientUrl. 

> getStation(uint256 stationId) returns(StationStruct) 

Получить полную актуальную информацию о станции по id. Возвращает полностью структуру `Station`

> getConnector(stationId, connectorId) returns(Connectors)

Получить состояние коннектора у конкретной станции, возвращает структуру `Connectors`

> setState(string memory clientUrl, bool state) 

Установить состояние станции (онлайн или офлайн)

> bootNotification(string memory clientUrl) 

Оповестить всех что станция загрузилась

> statusNotification(string memory clientUrl, int connectorId, int status, int errorCode) 

Оповестить всех что обновился статус коннектора

> heartbeat(string memory clientUrl) 

Оповестить всех что станция жива



### Транзакции

> remoteStartTransaction(string memory clientUrl, int connectorId, uint256 idtag) 

Отправить запрос на начало транзакции станции с конкретным коннектором

> rejectTransaction(uint256 transactionId) 

Отклонить запрос на начало транзакции

> remoteStopTransaction(string memory clientUrl, uint256 idtag) 

Отправить запрос на остановку транзакции

> getTransaction(uint256 id) public view returns(TransactionStruct.Fields memory) 

Получить текущее состояние транзакции по id

> getTransactionByIdtag(uint256 tagId) public view returns(uint256) 

Получить состояние транзакции по idtag

> startTransaction(string memory clientUrl, uint256 tagId, uint256 dateStart, uint256 meterStart) 

Отправить информацию о том что зарядка началась. 

> meterValues(string memory clientUrl, int connectorId,uint256 transactionId, TransactionStruct.MeterValue memory meterValue ) 

Отправить данные о метриках на конкретном коннекторе

> stopTransaction(string memory clientUrl, uint256 transactionId, uint256 dateStop, uint256 meterStop)

Отправить информацию о том что станция остановила транзакцию



## События

> BootNotification(uint256 indexed stationId, string clientUrl, uint256 timestamp)

Загрузка станции, обновляет поле heartbeat  структуре станции

> StatusNotification(uint256 indexed stationId, string clientUrl, int connectorId, int status, int errorCode ) 

Обновился статус коннектора

> Heartbeat(string clientUrl, uint256 timestamp)

Обновилось поле heartbeat структуре станции

> StartTransaction(string clientUrl, uint256 indexed transactionId, uint256 dateStart, uint256 meterStart) 

Началась зарядка на станции

> StopTransaction(string clientUrl, uint256 indexed transactionId, uint256 dateStop, uint256 meterStop) 

Остановилась зарядка на станции

> ChangeStateStation(uint256 indexed stationId, string clientUrl, bool state) 

Изменилось состояние станции (онлайн или офлайн)

> RemoteStartTransaction(string clientUrl, int connectorId, uint256 idtag, uint256 indexed transactionId)

Кто то отправил запрос на начало зарядки (сервер который управляет это зарядкой должен перехватить это событие и попробовать начать зарядку, т.е. отправить ocpp запрос на саму станцию, если зарядка началась, то должен выполнить запрос `StartTransaction` если нет, то `rejectTransaction`)

> MeterValues(string clientUrl, int connectorId, uint256 indexed transactionId, MeterValue ) 

Cтанция отправила текущий запрос meterValues (смотри документацию по ocpp, тут аналогично )

> RemoteStopTransaction(string clientUrl, uint256 indexed transactionId, int connectorId)

Cобытие для ocpp сервера, принимая это событие сервер должен останвить транзакцию. и выполнить запрос StopTransaction()

> RejectTransaction(uint256 indexed transactionId, string reason)

По этому событию можно отследить что станция отклонила запрос на старт транзакции. 


## From OCPI

by power
```
{
    "country_code": "RU",
    "owner": "", // if zero address, then can set for all. If have some kind owner, then only owner can set tariff to connector
    "id": "1",
    "currency": "RUB",
    "elements": [
        {
            "price_components": [
                {
                    "type": "ENERGY", 
                    // ENERGY Defined in kWh, step_size multiplier: 1 Wh
                    // FLAT Flat fee without unit for step_size
                    // PARKING_TIME Time not charging: defined in hours, step_size multiplier: 1 second
                    // TIME Time charging: defined in hours, step_size multiplier: 1 second. Can also be used in combination with a RESERVATION restriction to describe the price of the reservation time.
            
                    "price": 0.20,
                    "vat": 20.0,
                    "step_size": 1

                    // Minimum amount to be billed. This unit will be billed in this step_size
                    // blocks. Amounts that are less then this step_size are rounded up to
                    // the given step_size. For example: if type is TIME and step_size
                    // has a value of 300, then time will be billed in blocks of 5 minutes. If 6
                    // minutes were used, 10 minutes (2 blocks of step_size) will be billed                    
                }
            ],
            "restrictions": {
                "max_power": 16.00
                // start_time -  int in 24 howrs format, can be from 00 to 24
                // end_time - int in 24 howrs format, can be from 00 to 24
                // start_date - unixtime
                // end_date - unixtime 
                // min_kwh - Minimum consumed energy in kWh, for example 20, valid from this amount of energy (inclusive) being used.
                // max_kwh - Maximum consumed energy in kWh, for example 50, valid until this amount of energy (exclusive) being used.
                // min_current - Sum of the minimum current (in Amperes) over all phases, for example 5. When
                    // the EV is charging with more than, or equal to, the defined amount of current,
                    // this TariffElement is/becomes active. If the charging current is or becomes lower,
                    // this TariffElement is not or no longer valid and becomes inactive. This describes
                    // NOT the minimum current over the entire Charging Session. This restriction can
                    // make a TariffElement become active when the charging current is above the
                    // defined value, but the TariffElement MUST no longer be active when the
                    // charging current drops below the defined value.
                // max_current - Sum of the maximum current (in Amperes) over all phases, for example 20.
                    // When the EV is charging with less than the defined amount of current, this
                    // TariffElement becomes/is active. If the charging current is or becomes higher,
                    // this TariffElement is not or no longer valid and becomes inactive. This describes
                    // NOT the maximum current over the entire Charging Session. This restriction can
                    // make a TariffElement become active when the charging current is below this
                    // value, but the TariffElement MUST no longer be active when the charging
                    // current raises above the defined value.
                // min_power - in whatt
                // max_power - in whatt
                // min_duration -  duration in seconds
                // max_duration -  duration in seconds
            }
        },
        {
            "price_components": [
                {
                    "type": "ENERGY",
                    "price": 0.35,
                    "vat": 20.0,
                    "step_size": 1
                }
            ],
            "restrictions": {
                "max_power": 32.00
            }
        },
        {
            "price_components": [
                {
                    "type": "ENERGY",
                    "price": 0.50,
                    "vat": 20.0,
                    "step_size": 1
                }
            ]
        }
    ],
    "last_updated": "2018-12-05T12:01:09Z"
}
```


by time
```
{
    "country_code": "DE",
    "party_id": "ALL",
    "id": "2",
    "currency": "EUR",
    "type": "REGULAR",
    "elements": [
        {
            "price_components": [
                {
                    "type": "ENERGY",
                    "price": 0.00,
                    "vat": 20.0,
                    "step_size": 1
                }
            ],
            "restrictions": {
                "max_duration": 1800
            }
        },
        {
            "price_components": [
                {
                    "type": "ENERGY",
                    "price": 0.25,
                    "vat": 20.0,
                    "step_size": 1
                }
            ],
            "restrictions": {
                "max_duration": 3600
            }
        },
        {
            "price_components": [
                {
                    "type": "ENERGY",
                    "price": 0.40,
                    "vat": 20.0,
                    "step_size": 1
                }
            ]
        }
    ],
    "last_updated": "2018-12-05T13:12:44Z"
}
```