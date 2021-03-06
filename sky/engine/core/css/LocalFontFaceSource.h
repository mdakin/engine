// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_CSS_LOCALFONTFACESOURCE_H_
#define SKY_ENGINE_CORE_CSS_LOCALFONTFACESOURCE_H_

#include "sky/engine/core/css/CSSFontFaceSource.h"
#include "sky/engine/wtf/text/AtomicString.h"

namespace blink {

class LocalFontFaceSource : public CSSFontFaceSource {
public:
    LocalFontFaceSource(const String& fontName) : m_fontName(fontName) { }
    virtual bool isLocal() const { return true; }
    virtual bool isLocalFontAvailable(const FontDescription&) override;

private:
    virtual PassRefPtr<SimpleFontData> createFontData(const FontDescription&) override;

    class LocalFontHistograms {
    public:
        LocalFontHistograms() : m_reported(false) { }
        void record(bool loadSuccess);
    private:
        bool m_reported;
    };

    AtomicString m_fontName;
    LocalFontHistograms m_histograms;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_LOCALFONTFACESOURCE_H_
