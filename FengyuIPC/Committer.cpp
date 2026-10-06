#include "stdafx.h"
#include "Deserializer.h"
#include "Committer.h"
#include <FengyuUtility.h>

using namespace fengyu;

Deserializer::Ptr Committer::Create(ResponseParser* pTarget) {
  return Deserializer::Ptr(new Committer(pTarget));
}

Committer::Committer(ResponseParser* pTarget) : Deserializer(pTarget) {}

Committer::~Committer() {}

void Committer::Store(Deserializer::KeyType const& key,
                      std::wstring const& value) {
  if (!m_pTarget->p_commit)
    return;
  if (key.size() == 1) {
    *m_pTarget->p_commit = unescape_string(value);
  }
}
