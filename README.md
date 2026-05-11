1️⃣ Project Overview

This project presents an IoT-based intelligent vehicle monitoring and safety system developed using ESP32. The system integrates multiple sensors for real-time monitoring of vehicle condition, environmental parameters, obstacle detection, and power management. Sensor data is transmitted to the ThingSpeak cloud platform for remote monitoring and analysis. A 433 MHz RF communication system is implemented for real-time collision prevention, where obstacle detection triggers automatic motor stopping. The project also incorporates MATLAB-based machine learning models for crash detection and predictive maintenance, creating a compact and scalable smart vehicle safety prototype.

2️⃣ Problem Statement

Conventional low-cost vehicle monitoring systems mainly focus on data logging and post-event analysis rather than real-time safety response. Most systems lack immediate obstacle prevention mechanisms, local wireless communication, and predictive maintenance capabilities. Dependence on continuous internet connectivity and high-cost hardware further limits practical deployment in embedded applications. This project addresses these limitations by developing a low-cost, real-time vehicle monitoring and safety system with local RF-based response, cloud integration, and machine learning-based analysis.

3️⃣ System Architecture
Block Diagram

The system consists of:

ESP32 as the central controller
Multiple sensors for monitoring
ESP32-CAM for live video streaming
RF transmitter/receiver modules for safety communication
L293D motor driver for motor control
ThingSpeak cloud for IoT monitoring
Data Flow

Sensors → ESP32 → Data Processing →
• ThingSpeak Cloud Upload
• RF Signal Transmission
• Motor Control & Alerts

Communication Flow
Wi-Fi communication between ESP32 and ThingSpeak cloud
RF communication between transmitter and receiver modules
Local sensor-to-controller communication through ADC and digital GPIO interfaces

4️⃣ Hardware Used
ESP32 Dev Kit V1: Main processing and communication controller with Wi-Fi support.

QYF0900 MEMS Sensor: Used for vibration and crash detection.

IR Sensor: Used for obstacle detection and collision prevention.

DHT22 Sensor: Measures temperature and humidity.

MQ Gas Sensor: Detects gas/smoke concentration for safety monitoring.

Voltage & Current Sensors: Monitor battery voltage and power consumption.

ESP32-CAM: Provides live video streaming and surveillance.

433 MHz RF Module: Used for wireless safety communication and motor stopping.

L293D Motor Driver: Controls the DC motor operation.

5️⃣ Software & Tools
Arduino IDE: Used for ESP32 and Arduino programming.

MATLAB: Used for sensor analysis and machine learning implementation.

ThingSpeak: Cloud platform for real-time data monitoring and storage.

Python (Optional): Used for additional ML preprocessing and analytics.

6️⃣ Features Implemented
Real-time multi-sensor monitoring
Cloud-based data logging using ThingSpeak
Obstacle detection using IR sensor
RF-based wireless motor stopping mechanism
Live video streaming using ESP32-CAM
Crash/event detection using MEMS sensor
Voltage and current monitoring for battery analysis
Basic predictive maintenance functionality

7️⃣ Machine Learning Section
Crash Detection Model: A MEMS-based adaptive threshold model is used to classify:
Normal condition
Harsh braking
Pothole
Crash events

The model calculates baseline, deviation, and peak shock values for event detection.

Predictive Maintenance Model: Voltage and current sensor data are analyzed using trend analysis and statistical features such as:
Mean
Standard deviation
Voltage degradation slope

The model predicts:

Normal condition
Warning state
Potential battery/system failure

8️⃣ Results
Sensor Readings
The ESP32 successfully acquired and displayed real-time values including:

MEMS vibration
Gas level
Temperature & humidity
Voltage & current
IR obstacle status
