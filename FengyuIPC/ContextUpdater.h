#pragma once
#include "Deserializer.h"

class ContextUpdater : public fengyu::Deserializer {
 public:
  ContextUpdater(fengyu::ResponseParser* pTarget);
  virtual ~ContextUpdater();
  virtual void Store(fengyu::Deserializer::KeyType const& key,
                     std::wstring const& value);

  void _StoreText(fengyu::Text& target,
                  Deserializer::KeyType k,
                  std::wstring const& value);
  void _StoreCand(Deserializer::KeyType k, std::wstring const& value);

  static fengyu::Deserializer::Ptr Create(fengyu::ResponseParser* pTarget);
};

class StatusUpdater : public fengyu::Deserializer {
 public:
  StatusUpdater(fengyu::ResponseParser* pTarget);
  virtual ~StatusUpdater();
  virtual void Store(fengyu::Deserializer::KeyType const& key,
                     std::wstring const& value);

  static fengyu::Deserializer::Ptr Create(fengyu::ResponseParser* pTarget);
};
