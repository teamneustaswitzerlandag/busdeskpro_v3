library busdeskpro.globals;

String MandantAuth = "";
String PhoneNumberAuth = "";
String AuthCode = "";
String GoogleKey = "AIzaSyDjIyOeJktq5NohQimw-EPbirdPQwfOfHg";
String AppVersion = "3.0.1";
String? AppUserId = "";
var GblTenant = null;

List<dynamic> AllToursGbl = [];
List<dynamic> FilteredToursGbl = [];
List<bool> ExpandedToursGbl = [];
bool cacheTourList = false;
bool isLoading = true;
String loadingText = '';
List<dynamic> GblStops = [];
String TourNameGbl = '';
List<dynamic> ArrivalTimesReal = [];

var GlobalMapView = null;
var GlobalMapController = null;
var currentStoppIndex = 1;

var GblBusQR = '';
var GblMaterialQR = '';

int newsCount = 0;

var currentPosition = null;

var test2 = 'test';

var hereSDKInit = false;

var routeWaypointController;

String statusMessageGbl = "";
String verificationCodeGbl = "";

List<String> bufferOfLogTimesSend = [];
List<String> bufferOfLogTimesNotSend = [];
bool isConnectedToInternet = false;

bool isAndroidAutoConnected = false;