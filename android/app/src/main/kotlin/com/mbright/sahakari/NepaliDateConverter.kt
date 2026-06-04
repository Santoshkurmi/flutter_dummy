package com.mbright.sahakari

import java.util.Calendar
import java.util.TimeZone

object NepaliDateConverter {
    private val bsDateList = arrayOf(
        intArrayOf(2000, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        intArrayOf(2001, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2002, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        intArrayOf(2003, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        intArrayOf(2004, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        intArrayOf(2005, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2006, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        intArrayOf(2007, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        intArrayOf(2008, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31),
        intArrayOf(2009, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2010, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        intArrayOf(2011, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        intArrayOf(2012, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30),
        intArrayOf(2013, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2014, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        intArrayOf(2015, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        intArrayOf(2016, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30),
        intArrayOf(2017, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2018, 31, 32, 31, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        intArrayOf(2019, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        intArrayOf(2020, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2021, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2022, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30),
        intArrayOf(2023, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        intArrayOf(2024, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2025, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2026, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        intArrayOf(2027, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        intArrayOf(2028, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2029, 31, 31, 32, 31, 32, 30, 30, 29, 30, 29, 30, 30),
        intArrayOf(2030, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        intArrayOf(2031, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        intArrayOf(2032, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2033, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        intArrayOf(2034, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        intArrayOf(2035, 30, 32, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31),
        intArrayOf(2036, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2037, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        intArrayOf(2038, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        intArrayOf(2039, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30),
        intArrayOf(2040, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2041, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        intArrayOf(2042, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        intArrayOf(2043, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30),
        intArrayOf(2044, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2045, 31, 32, 31, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        intArrayOf(2046, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        intArrayOf(2047, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2048, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2049, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30),
        intArrayOf(2050, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        intArrayOf(2051, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2052, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2053, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30),
        intArrayOf(2054, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        intArrayOf(2055, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2056, 31, 31, 32, 31, 32, 30, 30, 29, 30, 29, 30, 30),
        intArrayOf(2057, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        intArrayOf(2058, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        intArrayOf(2059, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2060, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        intArrayOf(2061, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        intArrayOf(2062, 31, 31, 31, 32, 31, 31, 29, 30, 29, 30, 29, 31),
        intArrayOf(2063, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2064, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        intArrayOf(2065, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        intArrayOf(2066, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31),
        intArrayOf(2067, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2068, 31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        intArrayOf(2069, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        intArrayOf(2070, 31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30),
        intArrayOf(2071, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2072, 31, 32, 31, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        intArrayOf(2073, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        intArrayOf(2074, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2075, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2076, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30),
        intArrayOf(2077, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        intArrayOf(2078, 31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2079, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2080, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30),
        intArrayOf(2081, 31, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31),
        intArrayOf(2082, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2083, 31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30),
        intArrayOf(2084, 31, 31, 32, 31, 31, 30, 30, 30, 29, 30, 30, 30),
        intArrayOf(2085, 31, 32, 31, 32, 30, 31, 30, 30, 29, 30, 30, 30),
        intArrayOf(2086, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 30, 30),
        intArrayOf(2087, 31, 31, 32, 31, 31, 31, 30, 30, 30, 30, 30, 30),
        intArrayOf(2088, 30, 31, 32, 32, 30, 31, 30, 30, 29, 30, 30, 30),
        intArrayOf(2089, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 30, 30),
        intArrayOf(2090, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 30, 30),
        intArrayOf(2091, 31, 31, 32, 31, 31, 31, 30, 30, 29, 30, 30, 30),
        intArrayOf(2092, 30, 31, 32, 32, 31, 30, 30, 30, 29, 30, 30, 30),
        intArrayOf(2093, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 30, 30),
        intArrayOf(2094, 31, 31, 32, 31, 31, 30, 30, 30, 29, 30, 30, 30),
        intArrayOf(2095, 31, 31, 32, 31, 31, 31, 30, 29, 30, 30, 30, 30),
        intArrayOf(2096, 30, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30),
        intArrayOf(2097, 31, 32, 31, 31, 31, 30, 30, 30, 29, 30, 30, 30),
        intArrayOf(2098, 31, 31, 32, 31, 31, 31, 29, 30, 29, 30, 29, 31),
        intArrayOf(2099, 31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31),
        intArrayOf(2100, 30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31)
    )

    private val nepaliMonthsDevanagari = arrayOf(
        "वैशाख", "जेठ", "असार", "साउन", "भदौ", "असोज",
        "कात्तिक", "मंसिर", "पुस", "माघ", "फागुन", "चैत"
    )

    private val nepaliWeekdays = arrayOf(
        "आइतबार", "सोमबार", "मंगलबार", "बुधबार", "बिहीबार", "शुक्रबार", "शनिबार"
    )

    fun toNepaliNumbers(input: String): String {
        val english = charArrayOf('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')
        val nepali = charArrayOf('०', '१', '२', '३', '४', '५', '६', '७', '८', '९')
        var result = input
        for (i in english.indices) {
            result = result.replace(english[i], nepali[i])
        }
        return result
    }

    fun adToBs(yearAd: Int, monthAd: Int, dayAd: Int): IntArray {
        val calAd = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            set(yearAd, monthAd - 1, dayAd, 0, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val calRef = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            set(1943, Calendar.APRIL, 14, 0, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }

        val diffMs = calAd.timeInMillis - calRef.timeInMillis
        var diffDays = (diffMs / (24 * 60 * 60 * 1000)).toInt()

        if (diffDays < 0) {
            return intArrayOf(2000, 1, 1)
        }

        var yearBs = 2000
        var monthBs = 1
        var dayBs = 1

        var yearIdx = 0
        while (yearIdx < bsDateList.size) {
            val yearRow = bsDateList[yearIdx]
            val year = yearRow[0]

            var daysInYear = 0
            for (m in 1..12) {
                daysInYear += yearRow[m]
            }

            if (diffDays < daysInYear) {
                for (m in 1..12) {
                    val daysInMonth = yearRow[m]
                    if (diffDays < daysInMonth) {
                        yearBs = year
                        monthBs = m
                        dayBs = diffDays + 1
                        break
                    }
                    diffDays -= daysInMonth
                }
                break
            }
            diffDays -= daysInYear
            yearIdx++
        }

        return intArrayOf(yearBs, monthBs, dayBs)
    }

    private val englishMonths = arrayOf(
        "Baisakh", "Jestha", "Ashadh", "Shrawan", "Bhadra", "Ashwin",
        "Kartik", "Mangsir", "Poush", "Magh", "Falgun", "Chaitra"
    )

    private val englishWeekdays = arrayOf(
        "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"
    )

    fun getNepaliDateString(yearBs: Int, monthBs: Int, dayBs: Int, dayOfWeek: Int, isNepali: Boolean): String {
        return if (isNepali) {
            val monthNp = nepaliMonthsDevanagari[monthBs - 1]
            val dayNp = toNepaliNumbers(dayBs.toString())
            val yearNp = toNepaliNumbers(yearBs.toString())
            val weekdayNp = nepaliWeekdays[dayOfWeek % 7]
            "$monthNp $dayNp, $yearNp ($weekdayNp)"
        } else {
            val monthEn = englishMonths[monthBs - 1]
            val weekdayEn = englishWeekdays[dayOfWeek % 7]
            "$monthEn $dayBs, $yearBs ($weekdayEn)"
        }
    }
}
