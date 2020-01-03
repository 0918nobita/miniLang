module type MonadType = {
  type t('a);
  let empty: t('a);
  let singleton: 'a => t('a);
  let bind: (t('a), 'a => t('b)) => t('b);
};

module MakeMonad = (S: MonadType) => {
  let (>>=) = S.bind;
  let (=<<) = (f, m) => m >>= f;
  let (>>) = (precede, succeed) => precede >>= (_ => succeed);
  let fail = S.empty;
  let return = S.singleton;
};
