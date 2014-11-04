//
//  suncalc.swift
//  suncalc
//
//  Created by Shaun Meredith on 10/2/14.
//  Copyright (c) 2014 Chimani, LLC. All rights reserved.
//
//

import Foundation

class SunCalc {
	let J0:Double = 0.0009
	
	var sunrise:NSDate
	var sunriseEnd:NSDate
	var goldenHourEnd:NSDate
	var solarNoon:NSDate
	var goldenHour:NSDate
	var sunsetStart:NSDate
	var sunset:NSDate
	var dusk:NSDate
	var nauticalDusk:NSDate
	var night:NSDate
	var nadir:NSDate
	var nightEnd:NSDate
	var nauticalDawn:NSDate
	var dawn:NSDate
	
	class func getSetJ(h:Double, phi:Double, dec:Double, lw:Double, n:Double, M:Double, L:Double) -> Double {
		var w:Double = TimeUtils.getHourAngleH(h, phi: phi, d: dec)
		var a:Double = TimeUtils.getApproxTransitHt(w, lw: lw, n: n)
		
		return TimeUtils.getSolarTransitJDs(a, M: M, L: L)
	}
	
	class func getTimes(date:NSDate, latitude:Double, longitude:Double) -> SunCalc {
		return SunCalc(date:date, latitude:latitude, longitude:longitude)
	}
	
	class func getSunPosition(timeAndDate:NSDate, latitude:Double, longitude:Double) -> SunPosition {
		var lw:Double = Constants.RAD() * -longitude
		var phi:Double = Constants.RAD() * latitude
		var d:Double = DateUtils.toDays(timeAndDate)
		
		var c:EquatorialCoordinates = SunUtils.getSunCoords(d)
		var H:Double = PositionUtils.getSiderealTimeD(d, lw: lw) - c.rightAscension
		
		return SunPosition(azimuth: PositionUtils.getAzimuthH(H, phi: phi, dec: c.declination), altitude: PositionUtils.getAltitudeH(H, phi: phi, dec: c.declination))
	}
	
	class func getMoonPosition(timeAndDate:NSDate, latitude:Double, longitude:Double) -> MoonPosition {
		var lw:Double = Constants.RAD() * -longitude
		var phi:Double = Constants.RAD() * latitude
		var d:Double = DateUtils.toDays(timeAndDate)
		
		var c:GeocentricCoordinates = MoonUtils.getMoonCoords(d)
		var H:Double = PositionUtils.getSiderealTimeD(d, lw: lw) - c.rightAscension
		var h:Double = PositionUtils.getAltitudeH(H, phi: phi, dec: c.declination)
		
		// altitude correction for refraction
		h = h + Constants.RAD() * 0.017 / tan(h + Constants.RAD() * 10.26 / (h + Constants.RAD() * 5.10));
		
		return MoonPosition(azimuth: PositionUtils.getAzimuthH(H, phi: phi, dec: c.declination), altitude: h, distance: c.distance)
	}
	
	class func getMoonIllumination(timeAndDate:NSDate) -> MoonIllumination {
		var d:Double = DateUtils.toDays(timeAndDate)
		var s:EquatorialCoordinates = SunUtils.getSunCoords(d)
		var m:GeocentricCoordinates = MoonUtils.getMoonCoords(d)
		
		let sdist:Double = 149598000; // distance from Earth to Sun in km
		
		var phi:Double = acos(sin(s.declination) * sin(m.declination) + cos(s.declination) * cos(m.declination) * cos(s.rightAscension - m.rightAscension))
		var inc:Double = atan2(sdist * sin(phi), m.distance - sdist * cos(phi))
		var angle:Double = atan2(cos(s.declination) * sin(s.rightAscension - m.rightAscension), sin(s.declination) * cos(m.declination) - cos(s.declination) * sin(m.declination) * cos(s.rightAscension - m.rightAscension))
		
		var fraction:Double = (1 + cos(inc)) / 2
		var phase:Double = 0.5 + 0.5 * inc * (angle < 0 ? -1 : 1) / Constants.PI()
		
		return MoonIllumination(fraction: fraction, phase: phase, angle: angle)
	}
	
	init(date:NSDate, latitude:Double, longitude:Double) {
		var lw:Double = Constants.RAD() * -longitude
		var phi:Double = Constants.RAD() * latitude
		var d:Double = DateUtils.toDays(date)
		
		var n:Double = TimeUtils.getJulianCycleD(d, lw: lw)
		var ds:Double = TimeUtils.getApproxTransitHt(0, lw: lw, n: n)
		
		var M:Double = SunUtils.getSolarMeanAnomaly(ds)
		var L:Double = SunUtils.getEclipticLongitudeM(M)
		var dec:Double = PositionUtils.getDeclinationL(L, b: 0)
		
		var Jnoon:Double = TimeUtils.getSolarTransitJDs(ds, M: M, L: L)
		
		self.solarNoon = DateUtils.fromJulian(Jnoon)
		self.nadir = DateUtils.fromJulian(Jnoon - 0.5)
		
		// sun times configuration (angle, morning name, evening name)
		// unrolled the loop working on this data:
		// var times = [
		//             [-0.83, 'sunrise',       'sunset'      ],
		//             [ -0.3, 'sunriseEnd',    'sunsetStart' ],
		//             [   -6, 'dawn',          'dusk'        ],
		//             [  -12, 'nauticalDawn',  'nauticalDusk'],
		//             [  -18, 'nightEnd',      'night'       ],
		//             [    6, 'goldenHourEnd', 'goldenHour'  ]
		//             ];
		
		var h:Double = -0.83
		var Jset:Double = SunCalc.getSetJ(h * Constants.RAD(), phi: phi, dec: dec, lw: lw, n: n, M: M, L: L)
		var Jrise:Double = Jnoon - (Jset - Jnoon)
		
		self.sunrise = DateUtils.fromJulian(Jrise)
		self.sunset = DateUtils.fromJulian(Jset)
		
		h = -0.3;
		Jset = SunCalc.getSetJ(h * Constants.RAD(), phi: phi, dec: dec, lw: lw, n: n, M: M, L: L)
		Jrise = Jnoon - (Jset - Jnoon)
		self.sunriseEnd = DateUtils.fromJulian(Jrise)
		self.sunsetStart = DateUtils.fromJulian(Jset)
		
		h = -6;
		Jset = SunCalc.getSetJ(h * Constants.RAD(), phi: phi, dec: dec, lw: lw, n: n, M: M, L: L)
		Jrise = Jnoon - (Jset - Jnoon)
		self.dawn = DateUtils.fromJulian(Jrise)
		self.dusk = DateUtils.fromJulian(Jset)
		
		h = -12;
		Jset = SunCalc.getSetJ(h * Constants.RAD(), phi: phi, dec: dec, lw: lw, n: n, M: M, L: L)
		Jrise = Jnoon - (Jset - Jnoon)
		self.nauticalDawn = DateUtils.fromJulian(Jrise)
		self.nauticalDusk = DateUtils.fromJulian(Jset)
		
		h = -18;
		Jset = SunCalc.getSetJ(h * Constants.RAD(), phi: phi, dec: dec, lw: lw, n: n, M: M, L: L)
		Jrise = Jnoon - (Jset - Jnoon)
		self.nightEnd = DateUtils.fromJulian(Jrise)
		self.night = DateUtils.fromJulian(Jset)
		
		h = 6;
		Jset = SunCalc.getSetJ(h * Constants.RAD(), phi: phi, dec: dec, lw: lw, n: n, M: M, L: L)
		Jrise = Jnoon - (Jset - Jnoon)
		self.goldenHourEnd = DateUtils.fromJulian(Jrise)
		self.goldenHour = DateUtils.fromJulian(Jset)

	}
}