enum BSSTATE { BSUNUSED, BSUSED};
enum BSVALUE { BSFREE, BSACQUIRED };
struct bsem
{
    enum BSSTATE state;
    enum BSVALUE value;
    struct spinlock value_lock;
};
