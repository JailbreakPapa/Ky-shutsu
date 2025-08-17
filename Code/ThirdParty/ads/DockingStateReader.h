/*
 *   Copyright (c) 2023-present WD Studios Corp.
 *   All rights reserved.
 *   You are only allowed access to this code, if given WRITTEN permission by WD Studios Corp.
 */
#ifndef DockingStateReaderH
#define DockingStateReaderH
//============================================================================
/// \file   DockingStateReader.h
/// \author Uwe Kindler
/// \date   29.11.2019
/// \brief  Declaration of CDockingStateReader
//============================================================================

//============================================================================
//                                   INCLUDES
//============================================================================
#include <QXmlStreamReader>

namespace ads
{

/**
 * Extends QXmlStreamReader with file version information
 */
class CDockingStateReader : public QXmlStreamReader
{
private:
	int m_FileVersion;

public:
	using QXmlStreamReader::QXmlStreamReader;

	/**
	 * Set the file version for this state reader
	 */
	void setFileVersion(int FileVersion);

	/**
	 * Returns the file version set via setFileVersion
	 */
	int fileVersion() const;
};

} // namespace ads

//---------------------------------------------------------------------------
#endif // DockingStateReaderH
