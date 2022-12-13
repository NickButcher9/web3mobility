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
