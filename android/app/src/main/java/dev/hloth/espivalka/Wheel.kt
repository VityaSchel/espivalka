package dev.hloth.espivalka

import kotlin.math.cos
import kotlin.math.exp
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt
import kotlin.random.Random

const val FullTurn = 360f
const val SpinUpSeconds = 0.5f
const val CoastSeconds = 5.5f
private const val SettleSeconds = 1f
const val SpinSeconds = SpinUpSeconds + CoastSeconds + SettleSeconds

private const val SliceMargin = 0.1f
private const val MinExtraTurns = 3
private const val MaxExtraTurns = 6
private const val MaxOvershoot = 5f
private const val OvershootShare = 0.8f
private const val CoastDrag = 2f
private const val SettleStiffness = 120f
private const val SettleDampingRatio = 0.45f

private val coastDistanceScale = (exp(CoastDrag) - 1) / CoastDrag - 1
private val coastStartSpeed = (exp(CoastDrag) - 1) / coastDistanceScale
private val spinUpShare = coastStartSpeed * SpinUpSeconds / (2 * CoastSeconds)
private val settleNaturalFrequency = sqrt(SettleStiffness)
private val settleDecay = SettleDampingRatio * settleNaturalFrequency
private val settleFrequency = settleNaturalFrequency * sqrt(1 - SettleDampingRatio * SettleDampingRatio)

data class WheelSpin(val winner: Int, val finalRotation: Float, val overshoot: Float)

fun wheelShots(ratings: Map<String, Int>, random: Random): List<String> =
	shots.filterNot(ratings::containsKey).ifEmpty { shots }.shuffled(random)

fun <T> wheelColors(sliceCount: Int, palette: List<T>): List<T> = List(sliceCount) { slice ->
	val wrapsOntoFirst = slice > 0 && slice == sliceCount - 1 && slice % palette.size == 0
	palette[if (wrapsOntoFirst) 1 else slice % palette.size]
}

fun sliceAngle(sliceCount: Int): Float = FullTurn / sliceCount

fun sliceAtPointer(rotation: Float, sliceCount: Int): Int =
	((-rotation).mod(FullTurn) / sliceAngle(sliceCount)).toInt().coerceAtMost(sliceCount - 1)

fun finalRotation(slice: Int, offset: Float, sliceCount: Int, extraTurns: Int): Float =
	(extraTurns + 1) * FullTurn - (slice + offset) * sliceAngle(sliceCount)

fun randomSpin(sliceCount: Int, random: Random): WheelSpin {
	val winner = random.nextInt(sliceCount)
	val offset = SliceMargin + random.nextFloat() * (1 - 2 * SliceMargin)
	val extraTurns = random.nextInt(MinExtraTurns, MaxExtraTurns + 1)
	return WheelSpin(
		winner = winner,
		finalRotation = finalRotation(winner, offset, sliceCount, extraTurns),
		overshoot = min(MaxOvershoot, OvershootShare * min(offset, 1 - offset) * sliceAngle(sliceCount)),
	)
}

fun WheelSpin.rotationAt(seconds: Float): Float {
	val stop = finalRotation + overshoot
	val spinUpDistance = stop * spinUpShare / (1 + spinUpShare)
	val coastDistance = stop - spinUpDistance
	return when {
		seconds < SpinUpSeconds -> spinUpDistance * (seconds / SpinUpSeconds).pow(2)
		seconds < SpinUpSeconds + CoastSeconds -> spinUpDistance + coastDistance * coastProgress((seconds - SpinUpSeconds) / CoastSeconds)
		seconds < SpinSeconds -> finalRotation + overshoot * settleSwing(seconds - SpinUpSeconds - CoastSeconds)
		else -> finalRotation
	}
}

private fun coastProgress(fraction: Float): Float =
	((exp(CoastDrag) - exp(CoastDrag * (1 - fraction))) / CoastDrag - fraction) / coastDistanceScale

private fun settleSwing(seconds: Float): Float =
	exp(-settleDecay * seconds) * (cos(settleFrequency * seconds) + settleDecay / settleFrequency * sin(settleFrequency * seconds))
