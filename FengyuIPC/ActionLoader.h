#pragma once
#include "Deserializer.h"

class ActionLoader : public fengyu::Deserializer {
 public:
  ActionLoader(fengyu::ResponseParser* pTarget);
  virtual ~ActionLoader();
  // store data
  virtual void Store(fengyu::Deserializer::KeyType const& key,
                     std::wstring const& value);
  // factory method
  static fengyu::Deserializer::Ptr Create(fengyu::ResponseParser* pTarget);
};
