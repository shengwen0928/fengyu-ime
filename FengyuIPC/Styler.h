#pragma once

namespace fengyu {
class Deserializr;
}

class Styler : public fengyu::Deserializer {
 public:
  Styler(fengyu::ResponseParser* pTarget);
  virtual ~Styler();
  // store data
  virtual void Store(fengyu::Deserializer::KeyType const& key,
                     std::wstring const& value);
  // factory method
  static fengyu::Deserializer::Ptr Create(fengyu::ResponseParser* pTarget);
};
