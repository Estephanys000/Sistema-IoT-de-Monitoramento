#include <WiFi.h>
#include <PubSubClient.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h>

// IDENTIFICAÇÃO DA INSTÂNCIA
const char* ID_IDOSO = "idoso_02"; 
const char* TOPICO_PUBLISH = "mackenzie/saude/idoso_02/dados";

// CONFIGURAÇÕES DE REDE
const char* ssid = "Wokwi-GUEST";
const char* password = "";
const char* mqtt_server = "broker.hivemq.com";

// PINOS
const int PIN_BOTAO = 4;
const int PIN_BUZZER = 25;

// VARIÁVEIS DE CONTROLE DO ALARME
bool alarmeAtivo = false;
unsigned long ultimoTempoBuzzer = 0;
bool estadoBuzzer = false;

// VARIÁVEIS DE CONTROLE DO BOTÃO
bool estadoPanico = false;        // Estado atual do pânico (true/false persistente)
bool ultimoEstadoBotao = HIGH;    // Último estado lido do pino (HIGH = solto com PULLUP)
unsigned long ultimoDebounce = 0; // Controle de debounce
const int DEBOUNCE_MS = 50;       // Tempo de debounce em ms

WiFiClient espClient;
PubSubClient client(espClient);
Adafruit_MPU6050 mpu;

void setup() {
  Serial.begin(115200);
  pinMode(PIN_BOTAO, INPUT_PULLUP);
  pinMode(PIN_BUZZER, OUTPUT);
  digitalWrite(PIN_BUZZER, LOW);

  setup_wifi();
  client.setServer(mqtt_server, 1883);

  if (!mpu.begin()) {
    Serial.println("Falha ao encontrar o chip MPU6050");
    while (1) { delay(10); }
  }
  Serial.println("MPU6050 Inicializado com Sucesso!");
}

void setup_wifi() {
  delay(10);
  Serial.print("Conectando-se ao Wi-Fi...");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWi-Fi Conectado!");
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Tentando conexão MQTT...");
    if (client.connect(ID_IDOSO)) {
      Serial.println("Conectado ao Broker!");
    } else {
      Serial.print("Falhou, rc=");
      Serial.print(client.state());
      Serial.println(" Tentando novamente em 2 segundos");
      delay(2000);
    }
  }
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // --- LÓGICA DE TOGGLE COM DEBOUNCE ---
  bool leituraBotao = digitalRead(PIN_BOTAO);

  // Detecta borda de descida (solto→pressionado, pois PULLUP inverte)
  if (leituraBotao == LOW && ultimoEstadoBotao == HIGH) {
    if (millis() - ultimoDebounce > DEBOUNCE_MS) {
      estadoPanico = !estadoPanico; // Alterna o estado
      ultimoDebounce = millis();
      Serial.print("Botão de pânico: ");
      Serial.println(estadoPanico ? "ATIVADO" : "DESATIVADO");
    }
  }
  ultimoEstadoBotao = leituraBotao;

  // --- LEITURA DO SENSOR ---
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  float aceleracaoTotal = sqrt(
    pow(a.acceleration.x, 2) +
    pow(a.acceleration.y, 2) +
    pow(a.acceleration.z, 2)
  ) / 9.81;

  // --- LÓGICA DO ALARME ---
  if (aceleracaoTotal > 3.0) {
    alarmeAtivo = true;
  }

  // Botão de pânico desligado pelo toggle reseta o alarme
  if (!estadoPanico && alarmeAtivo) {
    alarmeAtivo = false;
    digitalWrite(PIN_BUZZER, LOW);
  }

  if (alarmeAtivo) {
    if (millis() - ultimoTempoBuzzer > 300) {
      ultimoTempoBuzzer = millis();
      estadoBuzzer = !estadoBuzzer;
      digitalWrite(PIN_BUZZER, estadoBuzzer ? HIGH : LOW);
    }
  }

  // --- ENVIO MQTT ---
  String payload = "{\"id\":\"" + String(ID_IDOSO) +
                   "\",\"aceleracao\":" + String(aceleracaoTotal, 2) +
                   ",\"panico\":" + String(estadoPanico ? "true" : "false") + "}";

  Serial.print("Publicando: ");
  Serial.println(payload);

  client.publish(TOPICO_PUBLISH, payload.c_str());

  delay(1000);
}