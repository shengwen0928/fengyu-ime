#pragma once
#include "Deserializer.h"

class Committer : public fengyu::Deserializer {
 public:
  Committer(fengyu::ResponseParser* pTarget);
  virtual ~Committer();
  // store data
  virtual void Store(fengyu::Deserializer::KeyType const& key,
                     std::wstring const& value);
  // factory method
  static fengyu::Deserializer::Ptr Create(fengyu::ResponseParser* pTarget);
};
