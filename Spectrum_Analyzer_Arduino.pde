import processing.sound.*;
import processing.serial.*;

FFT fft;                                        // Objeto FFT
AudioIn in;                                     // Entrada de Audio
Serial arduino;                                 

int bands = 512;                                 // Numero total de bandas en el espectro de audio
int numCols = 12;                               // Numero de columnas en la matriz
float[] Spectrum = new float[bands];            // Matriz para guardar los nuevos datos de banda fft
byte[] newBars = new byte[numCols];             // Esto mantendrá la matriz de bytes de datos formateados para ser enviados al arduino
float[] Bars = new float[numCols];              // Esto mantendrá la selección de las bandas que se formatearán en la matriz de bytes newBars

int gain = 150;                                 // Los datos FFT son muy pequeños asi que esto es como una preamplificacion de los datos
float barDecay = 0.6;                           // Como los FFTs son muy rapidos las barras saltarian y crearian solo un efecto de parpadeo
                                                // Asi que le sustraemos un valor de la amplitud actual de una barra disminuimos el proceso de decaimiento haciéndolo más atractivo
// Instrucciones para la version en la pantalla del analizador de espectro
int y_offset = 200;
int x_offset = 120;

void setup() {
  size(1000, 500, P2D);                         // Establecemos el tamaño de la ventana de visualización (para la versión en pantalla)
  strokeWeight(10);                             // Hacemos las barras mas delgadas
  
  // Creamos un flujo de entrada que se encamina en el analizador de amplitud
  fft = new FFT(this, bands);                   // Inicializamos el objeto fft
  in = new AudioIn(this, 0);                    // Inicializamos la entrada de audio la cual toma el audio de el dispositivo predeterminado de grabacion de windows
  
  in.start();                                   // Comnezamos a escuchar el flujo de audio de entrada
  fft.input(in);                                // Fijamos el flujo de audio como la entrada del objeto fft
  
  // Abrimos el puerto donde se encuentra el arduino Open the port you are using at the rate you want:
  printArray(Serial.list());
  arduino = new Serial(this, Serial.list()[0], 1000000); // TENEMOS QUE ASEGURARNOS LA VELOCIDAD DE BAUDIOS SEA LA MISMA QUE EN EL SKETCH DEL ARDUINO
}    

void draw() { 
  background(0);                                // Establecemos un fondo negro para la visualización en pantalla
  
  // Execute an fft
  fft.analyze(Spectrum);                        // Llenamos spectrum[] con amplitudes discretas
  int j = 0;                                   
  
  if(arduino.available() > 0)  {                // Los datos de ganancia de "ajuste fino" entrarán desde el lado del arduino
    gain = 4*arduino.read();                    // Capturamos los datos para un poco mas de manipulacion
    //println(gain);
  }
  
  for(int i = 0; i < numCols; i++)              // Empezamos a tomar las primeras bandas de datos del espectro
  {                                            
     stroke(255);                               // Instrucciones para la version en la pantalla del analizador de espectro
     line(j+x_offset, height-y_offset, j+x_offset, height-Spectrum[i]*height*5-y_offset);
     
     // Comenzamos a formatear los datos fft en material útil para el arduino
     newBars[i] = (byte)(Spectrum[i] * gain);
// Luego realizamos los cálculos necesarios para producir el efecto de decaimiento lento que queríamos    
     if(newBars[i] > Bars[i])  
       Bars[i] = newBars[i];
     else  {
       Bars[i] -= barDecay;
       if(Bars[i] < 0)
         Bars[i] = 0;
       newBars[i] = (byte) Bars[i];
     }
     j += 20;                                   // Mas instrucciones para la version en pantalla
  }
  arduino.write(newBars);                       // Mandamos las datos al arduino
  delay(40);                                   
}