/*=====================================================================

PIXHAWK Micro Air Vehicle Flying Robotics Toolkit

(c) 2009 PIXHAWK PROJECT  <http://pixhawk.ethz.ch>

This file is part of the PIXHAWK project

PIXHAWK is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

PIXHAWK is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PIXHAWK. If not, see <http://www.gnu.org/licenses/>.

======================================================================*/

/**
* @file
*   @brief Brief Description
*
*   @author Lorenz Meier <mavteam@student.ethz.ch>
*
*/

#include "LinkInterface.h"

bool LinkInterface::active(void)
{
    return _active;
}

void LinkInterface::setActive(bool active)
{
    _active = active;
    emit activeChanged(active);
}

LinkConfiguration* LinkInterface::getLinkConfiguration()
{
    return NULL;
}

void LinkInterface::_writeBytes(const QByteArray data)
{
    qDebug() << "called dummy write bytes";
}

bool LinkInterface::isLogReplay(void)
{
    return false;
}

void LinkInterface::enableDataRate(bool enable)
{
    _enableRateCollection = enable;
}


qint64 LinkInterface::getCurrentInputDataRate() const
{
    return _getCurrentDataRate(_inDataIndex, _inDataWriteTimes, _inDataWriteAmounts);
}

qint64 LinkInterface::getCurrentOutputDataRate() const
{
    return _getCurrentDataRate(_outDataIndex, _outDataWriteTimes, _outDataWriteAmounts);
}
    
uint8_t LinkInterface::getMavlinkChannel(void) const
{
    Q_ASSERT(_mavlinkChannelSet);
    return _mavlinkChannel;
}

void LinkInterface::writeBytesSafe(const char *bytes, int length)
{
    qDebug() << "called write bytes safe";
//    emit _invokeWriteBytes(QByteArray(bytes, length));

//    QMetaObject::invokeMethod(this, SLOT(_writeBytes(QByteArray)), Qt::QueuedConnection, QByteArray(bytes, length));
    _writeBytes(QByteArray(bytes, length));
}

LinkInterface::LinkInterface() :
    QThread(0)
  , _mavlinkChannelSet(false)
  , _active(false)
  , _enableRateCollection(false)
{
    // Initialize everything for the data rate calculation buffers.
    _inDataIndex  = 0;
    _outDataIndex = 0;

    // Initialize our data rate buffers.
    memset(_inDataWriteAmounts, 0, sizeof(_inDataWriteAmounts));
    memset(_inDataWriteTimes,   0, sizeof(_inDataWriteTimes));
    memset(_outDataWriteAmounts,0, sizeof(_outDataWriteAmounts));
    memset(_outDataWriteTimes,  0, sizeof(_outDataWriteTimes));

    qRegisterMetaType<LinkInterface*>("LinkInterface*");

//    moveToThread(this);
    // the self object always gets moved to a thread down the line. So always making a queued connection
    //        QObject::connect(this, &LinkInterface::_invokeWriteBytes, this, &LinkInterface::_writeBytes);
//    QObject::connect(this, SIGNAL(_invokeWriteBytes(QByteArray)), this, SLOT(_writeBytes(QByteArray)));
}

void LinkInterface::_logInputDataRate(quint64 byteCount, qint64 time) {
    if(_enableRateCollection)
        _logDataRateToBuffer(_inDataWriteAmounts, _inDataWriteTimes, &_inDataIndex, byteCount, time);
}

void LinkInterface::_logOutputDataRate(quint64 byteCount, qint64 time) {
    if(_enableRateCollection)
        _logDataRateToBuffer(_outDataWriteAmounts, _outDataWriteTimes, &_outDataIndex, byteCount, time);
}

void LinkInterface::_logDataRateToBuffer(quint64 *bytesBuffer, qint64 *timeBuffer, int *writeIndex, quint64 bytes, qint64 time)
{
    QMutexLocker dataRateLocker(&_dataRateMutex);

    int i = *writeIndex;

    // Now write into the buffer, if there's no room, we just overwrite the first data point.
    bytesBuffer[i] = bytes;
    timeBuffer[i] = time;

    // Increment and wrap the write index
    ++i;
    if (i == _dataRateBufferSize)
    {
        i = 0;
    }
    *writeIndex = i;
}

qint64 LinkInterface::_getCurrentDataRate(int index, const qint64 dataWriteTimes[], const quint64 dataWriteAmounts[]) const
{
    const qint64 now = QDateTime::currentMSecsSinceEpoch();

    // Limit the time we calculate to the recent past
    const qint64 cutoff = now - _dataRateCurrentTimespan;

    // Grab the mutex for working with the stats variables
    QMutexLocker dataRateLocker(&_dataRateMutex);

    // Now iterate through the buffer of all received data packets adding up all values
    // within now and our cutof.
    qint64 totalBytes = 0;
    qint64 totalTime = 0;
    qint64 lastTime = 0;
    int size = _dataRateBufferSize;
    while (size-- > 0)
    {
        // If this data is within our cutoff time, include it in our calculations.
        // This also accounts for when the buffer is empty and filled with 0-times.
        if (dataWriteTimes[index] > cutoff && lastTime > 0) {
            // Track the total time, using the previous time as our timeperiod.
            totalTime += dataWriteTimes[index] - lastTime;
            totalBytes += dataWriteAmounts[index];
        }

        // Track the last time sample for doing timespan calculations
        lastTime = dataWriteTimes[index];

        // Increment and wrap the index if necessary.
        if (++index == _dataRateBufferSize)
        {
            index = 0;
        }
    }

    // Return the final calculated value in bits / s, converted from bytes/ms.
    qint64 dataRate = (totalTime != 0)?(qint64)((float)totalBytes * 8.0f / ((float)totalTime / 1000.0f)):0;

    // Finally return our calculated data rate.
    return dataRate;
}

/// Sets the mavlink channel to use for this link
void LinkInterface::_setMavlinkChannel(uint8_t channel)
{
    Q_ASSERT(!_mavlinkChannelSet); _mavlinkChannelSet = true; _mavlinkChannel = channel;
}
