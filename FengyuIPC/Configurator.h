#pragma once
#include "Deserializer.h"

class Configurator : public fengyu::Deserializer {
 public:
  Configurator(fengyu::ResponseParser* pTarget);
  virtual ~Configurator();
  // store data
  virtual void Store(fengyu::Deserializer::KeyType const& key,
                     std::wstring const& value);
  // factory method
  static fengyu::Deserializer::Ptr Create(fengyu::ResponseParser* pTarget);
};
