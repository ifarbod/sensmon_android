import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:io';

const paths = [
    "/sys/devices/system/cpu/cpu0/cpufreq/cpu_temp",
    "/sys/devices/system/cpu/cpu0/cpufreq/FakeShmoo_cpu_temp",
    "/sys/devices/platform/omap/omap_temp_sensor.0/temperature",
    "/sys/devices/platform/omap_i2c.1/i2c-1/1-0055/power_supply/bq27520-0/temp",
    "/sys/devices/platform/tegra-i2c.3/i2c-4/4-004c/temperature",
    "/sys/devices/platform/tegra_tmon/temp1_input",
    "/sys/devices/platform/tegra-i2c.3/i2c-4/4-004c/ext_temperature",
    "/sys/devices/platform/tegra-tsensor/tsensor_temperature",
    "/sys/kernel/debug/tegra_thermal/temp_tj",
    "/sys/devices/platform/s5p-tmu/temperature",
    "/sys/devices/platform/s5p-tmu/curr_temp",
    "/sys/devices/platform/s5p-tmu/temperature",
    "/sys/class/hwmon/hwmon0/device/temp1_input",
    "/sys/class/hw_thermal/temp",
    "/sys/devices/virtual/sec/sec-pa-thermistor/temperature",
    "/sys/devices/virtual/sec/sec-ap-thermistor/temperature", // Galaxy A50
    "/sys/devices/platform/battery/power_supply/battery/temp",
    "/sys/devices/virtual/nxp/tfa_cal/temp",
    "/sys/devices/virtual/sec/exynos_tmu/curr_temp",
    "/sys/htc/cpu_temp",
    "/vendor/bin/mktemp",
    "/system/bin/mktemp",
    "/sys/devices/platform/10080000.ISP/temp",
    "/sys/devices/platform/10080000.LITTLE/temp",
    "/sys/devices/platform/10080000.CP/temp",
    "/sys/devices/platform/10080000.BIG/temp",
    "/sys/devices/platform/10080000.G3D/temp",
    "/sys/devices/platform/10080000.NPU/temp",
    "/sys/devices/virtual/sensors/gyro_sensor/temperature",
    "/sys/devices/virtual/audio/amp/curr_temperature_0"
];

// others
const hwmonNamePaths = [
    "/sys/class/thermal/thermal_zone*/type",
    "/sys/devices/virtual/thermal/thermal_zone*/type",
    "/sys/class/hwmon/hwmon*/name",
    "/sys/devices/virtual/hwmon/hwmon*/name"
];

const hwmonValuesPaths = [
    "/sys/class/thermal/thermal_zone*/temp",
    "/sys/devices/virtual/thermal/thermal_zone*/temp",
    "/sys/class/hwmon/hwmon*/temp1_input",
    "/sys/devices/virtual/hwmon/hwmon*/temp1_input",
];

Future<String> getHwmonTemperatureName(String path, [int index = -1]) async {
    final temperatureFile = File(index == -1 ? path : path.replaceAll('*', index.toString()));
    if (!await temperatureFile.exists()) {
        final split = path.split('/');
        return split[split.length - 2].replaceAll('*', index.toString());
    }

    var lines = [];
    try {
        lines = await temperatureFile.readAsLines();
    } on FileSystemException catch (_, e) {
        print(e.toString());
    }

    for (final line in lines) {
        final temperature = line.trim();
        return temperature;
    }
    // Handle the case where the temperature wasn't found in the file.
    final split = path.split('/');
    return split[split.length - 2].replaceAll('*', index.toString());
}

Future<double> getHwmonTemperatureValue(String path, [int index = -1]) async {
    final temperatureFile = File(index == -1 ? path : path.replaceAll('*', index.toString()));
    if (!await temperatureFile.exists()) {
        return 0.0;
    }

    var lines = [];
    try {
        lines = await temperatureFile.readAsLines();
    } on FileSystemException catch (_, e) {
        print(e.toString());
    }

    for (final line in lines) {
        final temperature = double.tryParse(line.split(':').last.trim())! / 10;
        return temperature;
    }
    return 0.0;
}

void main() {
    runApp(const SensmonApp());
}

class SensmonApp extends StatelessWidget {
    const SensmonApp({super.key});

    // This widget is the root of your application.
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'Sensmon Android',
            theme: ThemeData(
                useMaterial3: true,
                primarySwatch: Colors.blue,
            ),
            home: const MyHomePage(title: 'Sensmon Home Page'),
        );
    }
}

class MyHomePage extends StatefulWidget {
    const MyHomePage({super.key, required this.title});

    final String title;

    @override
    State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
    List<String> names = [];
    List<double> data = [];

    @override
    void initState() {
        super.initState();
        loadData();

        Timer.periodic(const Duration(seconds: 2), (timer) {
            loadData();
        });
    }

    Future<void> loadData() async {
        for (var element in hwmonNamePaths) {
            if (element.contains("thermal_zone")) {
                for (var i = 0; i < 94; i++) {
                    names.add(await getHwmonTemperatureName(element, i));
                }
            } else if (element.contains("hwmon")) {
                for (var i = 0; i < 10; i++) {
                    names.add(await getHwmonTemperatureName(element, i));
                }
            }
        }
        for (var element in hwmonValuesPaths) {
            if (element.contains("thermal_zone")) {
                for (var i = 0; i < 94; i++) {
                    data.add(await getHwmonTemperatureValue(element, i));
                }
            } else if (element.contains("hwmon")) {
                for (var i = 0; i < 10; i++) {
                    data.add(await getHwmonTemperatureValue(element, i));
                }
            }
        }
        setState(() {
            names = names;
            data = data;
        });
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            body: Column(
                children: <Widget>[
                    Expanded(
                        child: ListView.builder(
                            itemCount: names.length,
                            itemBuilder: (BuildContext context, int index) {
                                return ListTile(
                                    title: Text("${names[index]} = ${data[index].toString()}"),
                                );
                            },
                        ),
                    ),
                ],
            ),
            floatingActionButton: FloatingActionButton.extended(
                onPressed: () {},
                label: const Text('Test'),
                icon: const Icon(Icons.one_k),
            ),
        );
    }
}
